/**************************************************************************/
/*  libgodot.h                                                            */
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

#pragma once

#include "gdextension_interface.gen.h"

#ifdef __cplusplus
extern "C" {
#endif

// Export macros for DLL visibility
#if defined(_MSC_VER) || defined(__MINGW32__)
#define LIBGODOT_API __declspec(dllexport)
#elif defined(__GNUC__) || defined(__clang__)
#define LIBGODOT_API __attribute__((visibility("default")))
#endif // if defined(_MSC_VER)

/**
 * @name libgodot_create_godot_instance
 * @since 4.6
 *
 * Creates a new Godot instance.
 *
 * @param p_argc The number of command line arguments.
 * @param p_argv The C-style array of command line arguments.
 * @param p_init_func GDExtension initialization function of the host application.
 *
 * @return A pointer to created \ref GodotInstance GDExtension object or nullptr if there was an error.
 */
LIBGODOT_API GDExtensionObjectPtr libgodot_create_godot_instance(int p_argc, char *p_argv[], GDExtensionInitializationFunction p_init_func);

/**
 * @name libgodot_destroy_godot_instance
 * @since 4.6
 *
 * Destroys an existing Godot instance.
 *
 * @param p_godot_instance The reference to the GodotInstance object to destroy.
 *
 */
LIBGODOT_API void libgodot_destroy_godot_instance(GDExtensionObjectPtr p_godot_instance);

/**
 * @name libgodot_get_embedded_context_id
 * @since 4.6
 *
 * Gets the CAContext ID for the embedded display server's rendering layer.
 * This ID can be used with CALayerHost to display Godot's rendering in a host view.
 * Only valid when using --display-driver embedded on macOS.
 *
 * @return The CAContext contextId, or 0 if embedded display server is not active.
 */
LIBGODOT_API uint32_t libgodot_get_embedded_context_id(void);

/**
 * @name libgodot_get_embedded_layer
 * @since 4.6
 *
 * Gets the CALayer pointer for the embedded display server's rendering layer.
 * This can be used for same-process embedding by adding as a sublayer.
 * Only valid when using --display-driver embedded on macOS.
 *
 * @return The CALayer pointer, or NULL if embedded display server is not active.
 */
LIBGODOT_API void *libgodot_get_embedded_layer(void);

/**
 * @name libgodot_set_embedded_window_size
 * @since 4.6
 *
 * Sets the size of the embedded display server's window/viewport.
 * Use this to resize the Godot rendering to match the host view's dimensions.
 * Only valid when using --display-driver embedded.
 *
 * @param p_width The new width in pixels.
 * @param p_height The new height in pixels.
 */
LIBGODOT_API void libgodot_set_embedded_window_size(int p_width, int p_height);

/**
 * @name libgodot_send_mouse_button
 * @since 4.6
 *
 * Sends a mouse button event to the embedded display server.
 *
 * @param p_button Mouse button index (1=left, 2=right, 3=middle, 4=wheel_up, 5=wheel_down).
 * @param p_pressed True if button pressed, false if released.
 * @param p_x X position in pixels.
 * @param p_y Y position in pixels.
 * @param p_double_click True if this is a double-click.
 */
LIBGODOT_API void libgodot_send_mouse_button(int p_button, bool p_pressed, float p_x, float p_y, bool p_double_click);

/**
 * @name libgodot_send_mouse_motion
 * @since 4.6
 *
 * Sends a mouse motion event to the embedded display server.
 *
 * @param p_x X position in pixels.
 * @param p_y Y position in pixels.
 * @param p_rel_x Relative X movement.
 * @param p_rel_y Relative Y movement.
 * @param p_button_mask Bitmask of currently pressed buttons.
 */
LIBGODOT_API void libgodot_send_mouse_motion(float p_x, float p_y, float p_rel_x, float p_rel_y, int p_button_mask);

/**
 * @name libgodot_send_key
 * @since 4.6
 *
 * Sends a keyboard event to the embedded display server.
 * Note: Consider using libgodot_send_key_event instead, which uses Godot's
 * internal key mapping and handles keyboard layouts correctly.
 *
 * @param p_keycode The Godot keycode (Key enum value).
 * @param p_physical_keycode The physical key scancode.
 * @param p_unicode The Unicode character (0 if none).
 * @param p_pressed True if key pressed, false if released.
 * @param p_echo True if this is a key repeat.
 * @param p_shift True if Shift modifier is pressed.
 * @param p_ctrl True if Control modifier is pressed.
 * @param p_alt True if Alt/Option modifier is pressed.
 * @param p_meta True if Meta/Command modifier is pressed.
 */
LIBGODOT_API void libgodot_send_key(int p_keycode, int p_physical_keycode, int p_unicode, bool p_pressed, bool p_echo, bool p_shift, bool p_ctrl, bool p_alt, bool p_meta);

/**
 * @name libgodot_send_key_event
 * @since 4.6
 *
 * Sends a keyboard event using raw macOS event data.
 * This function uses Godot's internal KeyMappingMacOS to properly handle
 * keyboard layout remapping and modifier extraction.
 *
 * @param p_keycode The macOS virtual keycode (NSEvent.keyCode).
 * @param p_modifier_flags The macOS modifier flags (NSEvent.modifierFlags).
 * @param p_pressed True if key pressed, false if released.
 * @param p_echo True if this is a key repeat.
 * @param p_characters UTF-8 encoded characters from NSEvent.characters (can be NULL).
 */
LIBGODOT_API void libgodot_send_key_event(uint16_t p_keycode, uint32_t p_modifier_flags, bool p_pressed, bool p_echo, const char *p_characters);

/**
 * @name libgodot_send_scroll
 * @since 4.6
 *
 * Sends a scroll wheel event to the embedded display server.
 *
 * @param p_x X position in pixels.
 * @param p_y Y position in pixels.
 * @param p_delta_x Horizontal scroll amount.
 * @param p_delta_y Vertical scroll amount.
 */
LIBGODOT_API void libgodot_send_scroll(float p_x, float p_y, float p_delta_x, float p_delta_y);

/**
 * @name libgodot_send_focus_in
 * @since 4.6
 *
 * Notifies Godot that the embedded view has gained focus.
 * This should be called when the host view becomes the first responder
 * or when the host window becomes key window.
 */
LIBGODOT_API void libgodot_send_focus_in(void);

/**
 * @name libgodot_send_focus_out
 * @since 4.6
 *
 * Notifies Godot that the embedded view has lost focus.
 * This should be called when the host view resigns first responder
 * or when the host window resigns key window.
 * This also releases any currently pressed keys/buttons.
 */
LIBGODOT_API void libgodot_send_focus_out(void);

#ifdef __cplusplus
}
#endif
