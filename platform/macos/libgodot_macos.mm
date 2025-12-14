/**************************************************************************/
/*  libgodot_macos.mm                                                     */
/**************************************************************************/
/*                         This file is part of:                          */
/*                             GODOT ENGINE                               */
/*                        https://godotengine.org                         */
/**************************************************************************/
/* Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md). */
/* Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.                  */
/*                                                                        */
/* Permission is hereby granted, free of charge, to any person obtaining  */
/* a copy of this software and associated documentation files (the        */
/* "Software"), to deal in the Software without restriction, including    */
/* without limitation the rights to use, copy, modify, merge, publish,    */
/* distribute, sublicense, and/or sell copies of the Software, and to     */
/* permit persons to whom the Software is furnished to do so, subject to  */
/* the following conditions:                                              */
/*                                                                        */
/* The above copyright notice and this permission notice shall be         */
/* included in all copies or substantial portions of the Software.        */
/*                                                                        */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. */
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 */
/**************************************************************************/

#include "core/extension/libgodot.h"

#include "core/extension/godot_instance.h"
#include "core/input/input.h"
#include "core/input/input_event.h"
#include "main/main.h"
#include "servers/display/display_server.h"

#include "os_macos.h"
#include "display_server_embedded.h"
#include "key_mapping_macos.h"

#import <AppKit/AppKit.h>

static OS_MacOS *os = nullptr;

static GodotInstance *instance = nullptr;

GDExtensionObjectPtr libgodot_create_godot_instance(int p_argc, char *p_argv[], GDExtensionInitializationFunction p_init_func) {
	ERR_FAIL_COND_V_MSG(instance != nullptr, nullptr, "Only one Godot Instance may be created.");

	uint32_t remaining_args = p_argc - 1;
	os = new OS_MacOS_NSApp(p_argv[0], remaining_args, remaining_args > 0 ? &p_argv[1] : nullptr);

	// Register the embedded display driver for in-process rendering
	DisplayServerEmbedded::register_embedded_driver();

	@autoreleasepool {
		Error err = Main::setup(p_argv[0], remaining_args, remaining_args > 0 ? &p_argv[1] : nullptr, false);
		if (err != OK) {
			return nullptr;
		}

		instance = memnew(GodotInstance);
		if (!instance->initialize(p_init_func)) {
			memdelete(instance);
			instance = nullptr;
			return nullptr;
		}

		return (GDExtensionObjectPtr)instance;
	}
}

void libgodot_destroy_godot_instance(GDExtensionObjectPtr p_godot_instance) {
	GodotInstance *godot_instance = (GodotInstance *)p_godot_instance;
	if (instance == godot_instance) {
		godot_instance->stop();
		memdelete(godot_instance);
		// Note: When Godot Engine supports reinitialization, clear the instance pointer here.
		//instance = nullptr;
		Main::cleanup();
	}
}

uint32_t libgodot_get_embedded_context_id(void) {
	DisplayServer *ds = DisplayServer::get_singleton();
	if (ds && ds->get_name() == "embedded") {
		DisplayServerEmbedded *ds_embedded = static_cast<DisplayServerEmbedded *>(ds);
		return ds_embedded->get_context_id();
	}
	return 0;
}

void *libgodot_get_embedded_layer(void) {
	DisplayServer *ds = DisplayServer::get_singleton();
	if (ds && ds->get_name() == "embedded") {
		DisplayServerEmbedded *ds_embedded = static_cast<DisplayServerEmbedded *>(ds);
		return ds_embedded->get_layer();
	}
	return nullptr;
}

void libgodot_set_embedded_window_size(int p_width, int p_height) {
	DisplayServer *ds = DisplayServer::get_singleton();
	if (ds && ds->get_name() == "embedded") {
		DisplayServerEmbedded *ds_embedded = static_cast<DisplayServerEmbedded *>(ds);
		print_line(vformat("libgodot_set_embedded_window_size: %dx%d", p_width, p_height));
		ds_embedded->_window_set_size(Size2i(p_width, p_height));
	}
}

// Store mouse position and button state for embedded input
static Point2 embedded_mouse_pos;
static BitField<MouseButtonMask> embedded_button_mask;

void libgodot_send_mouse_button(int p_button, bool p_pressed, float p_x, float p_y, bool p_double_click) {
	Input *input = Input::get_singleton();
	if (!input) {
		return;
	}

	embedded_mouse_pos = Point2(p_x, p_y);

	// Update button mask
	MouseButton button = static_cast<MouseButton>(p_button);
	MouseButtonMask mask;
	switch (button) {
		case MouseButton::LEFT:
			mask = MouseButtonMask::LEFT;
			break;
		case MouseButton::RIGHT:
			mask = MouseButtonMask::RIGHT;
			break;
		case MouseButton::MIDDLE:
			mask = MouseButtonMask::MIDDLE;
			break;
		default:
			mask = MouseButtonMask::LEFT;
			break;
	}

	if (p_pressed) {
		embedded_button_mask.set_flag(mask);
	} else {
		embedded_button_mask.clear_flag(mask);
	}

	Ref<InputEventMouseButton> mb;
	mb.instantiate();
	mb->set_window_id(DisplayServer::MAIN_WINDOW_ID);
	mb->set_button_index(button);
	mb->set_pressed(p_pressed);
	mb->set_position(embedded_mouse_pos);
	mb->set_global_position(embedded_mouse_pos);
	mb->set_button_mask(embedded_button_mask);
	mb->set_double_click(p_double_click);

	input->parse_input_event(mb);
}

void libgodot_send_mouse_motion(float p_x, float p_y, float p_rel_x, float p_rel_y, int p_button_mask) {
	Input *input = Input::get_singleton();
	if (!input) {
		return;
	}

	Point2 old_pos = embedded_mouse_pos;
	embedded_mouse_pos = Point2(p_x, p_y);
	embedded_button_mask = BitField<MouseButtonMask>(p_button_mask);

	Ref<InputEventMouseMotion> mm;
	mm.instantiate();
	mm->set_window_id(DisplayServer::MAIN_WINDOW_ID);
	mm->set_button_mask(embedded_button_mask);
	mm->set_position(embedded_mouse_pos);
	mm->set_global_position(embedded_mouse_pos);
	mm->set_relative(Vector2(p_rel_x, p_rel_y));
	mm->set_velocity(input->get_last_mouse_velocity());

	input->parse_input_event(mm);
}

void libgodot_send_key(int p_keycode, int p_physical_keycode, int p_unicode, bool p_pressed, bool p_echo, bool p_shift, bool p_ctrl, bool p_alt, bool p_meta) {
	Input *input = Input::get_singleton();
	if (!input) {
		return;
	}

	Ref<InputEventKey> k;
	k.instantiate();
	k->set_window_id(DisplayServer::MAIN_WINDOW_ID);
	k->set_keycode(static_cast<Key>(p_keycode));
	k->set_physical_keycode(static_cast<Key>(p_physical_keycode));
	k->set_unicode(p_unicode);
	k->set_pressed(p_pressed);
	k->set_echo(p_echo);
	k->set_shift_pressed(p_shift);
	k->set_ctrl_pressed(p_ctrl);
	k->set_alt_pressed(p_alt);
	k->set_meta_pressed(p_meta);

	input->parse_input_event(k);
}

void libgodot_send_scroll(float p_x, float p_y, float p_delta_x, float p_delta_y) {
	Input *input = Input::get_singleton();
	if (!input) {
		return;
	}

	embedded_mouse_pos = Point2(p_x, p_y);

	// Vertical scroll
	if (p_delta_y != 0) {
		MouseButton button = p_delta_y > 0 ? MouseButton::WHEEL_UP : MouseButton::WHEEL_DOWN;

		Ref<InputEventMouseButton> mb;
		mb.instantiate();
		mb->set_window_id(DisplayServer::MAIN_WINDOW_ID);
		mb->set_button_index(button);
		mb->set_pressed(true);
		mb->set_position(embedded_mouse_pos);
		mb->set_global_position(embedded_mouse_pos);
		mb->set_factor(Math::abs(p_delta_y));
		input->parse_input_event(mb);

		// Release
		mb.instantiate();
		mb->set_window_id(DisplayServer::MAIN_WINDOW_ID);
		mb->set_button_index(button);
		mb->set_pressed(false);
		mb->set_position(embedded_mouse_pos);
		mb->set_global_position(embedded_mouse_pos);
		input->parse_input_event(mb);
	}

	// Horizontal scroll
	if (p_delta_x != 0) {
		MouseButton button = p_delta_x > 0 ? MouseButton::WHEEL_RIGHT : MouseButton::WHEEL_LEFT;

		Ref<InputEventMouseButton> mb;
		mb.instantiate();
		mb->set_window_id(DisplayServer::MAIN_WINDOW_ID);
		mb->set_button_index(button);
		mb->set_pressed(true);
		mb->set_position(embedded_mouse_pos);
		mb->set_global_position(embedded_mouse_pos);
		mb->set_factor(Math::abs(p_delta_x));
		input->parse_input_event(mb);

		// Release
		mb.instantiate();
		mb->set_window_id(DisplayServer::MAIN_WINDOW_ID);
		mb->set_button_index(button);
		mb->set_pressed(false);
		mb->set_position(embedded_mouse_pos);
		mb->set_global_position(embedded_mouse_pos);
		input->parse_input_event(mb);
	}
}

void libgodot_send_key_event(uint16_t p_keycode, uint32_t p_modifier_flags, bool p_pressed, bool p_echo, const char *p_characters) {
	Input *input = Input::get_singleton();
	if (!input) {
		return;
	}

	// Use Godot's KeyMappingMacOS to properly map keys with keyboard layout support.
	// This mirrors what godot_content_view.mm does in keyDown/keyUp/flagsChanged.

	Key keycode = KeyMappingMacOS::remap_key(p_keycode, p_modifier_flags, false);
	Key physical_keycode = KeyMappingMacOS::translate_key(p_keycode);
	Key key_label = KeyMappingMacOS::remap_key(p_keycode, p_modifier_flags, true);
	KeyLocation location = KeyMappingMacOS::translate_location(p_keycode);

	// Extract unicode from characters string
	char32_t unicode = 0;
	if (p_characters && p_characters[0]) {
		String chars = String::utf8(p_characters);
		if (!chars.is_empty()) {
			unicode = chars[0];
		}
	}

	Ref<InputEventKey> k;
	k.instantiate();
	k->set_window_id(DisplayServer::MAIN_WINDOW_ID);

	// Set modifiers from raw macOS flags (same as get_key_modifier_state in display_server_macos.mm)
	k->set_shift_pressed((p_modifier_flags & NSEventModifierFlagShift) != 0);
	k->set_ctrl_pressed((p_modifier_flags & NSEventModifierFlagControl) != 0);
	k->set_alt_pressed((p_modifier_flags & NSEventModifierFlagOption) != 0);
	k->set_meta_pressed((p_modifier_flags & NSEventModifierFlagCommand) != 0);

	k->set_pressed(p_pressed);
	k->set_echo(p_echo);
	k->set_keycode(keycode);
	k->set_physical_keycode(physical_keycode);
	k->set_key_label(key_label);
	k->set_unicode(unicode);
	k->set_location(location);

	input->parse_input_event(k);
}

void libgodot_send_focus_in(void) {
	DisplayServer *ds = DisplayServer::get_singleton();
	if (ds && ds->get_name() == "embedded") {
		DisplayServerEmbedded *ds_embedded = static_cast<DisplayServerEmbedded *>(ds);
		ds_embedded->send_window_event(DisplayServer::WINDOW_EVENT_FOCUS_IN, DisplayServer::MAIN_WINDOW_ID);
	}
}

void libgodot_send_focus_out(void) {
	// Release all pressed keys/buttons when losing focus
	Input *input = Input::get_singleton();
	if (input) {
		input->release_pressed_events();
	}

	DisplayServer *ds = DisplayServer::get_singleton();
	if (ds && ds->get_name() == "embedded") {
		DisplayServerEmbedded *ds_embedded = static_cast<DisplayServerEmbedded *>(ds);
		ds_embedded->send_window_event(DisplayServer::WINDOW_EVENT_FOCUS_OUT, DisplayServer::MAIN_WINDOW_ID);
	}
}
