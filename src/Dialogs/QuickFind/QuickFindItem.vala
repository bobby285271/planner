/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alain M. <alainmh23@gmail.com>
*/

public class Dialogs.QuickFind.QuickFindItem : Gtk.ListBoxRow {
    public Objects.BaseObject base_object { get; construct; }
    public string pattern { get; construct; }

    public QuickFindItem (Objects.BaseObject base_object, string pattern) {
        Object (
            base_object: base_object,
            pattern: pattern,
            margin_start: 3,
            margin_end: 3
        );
    }

    construct {
        unowned Gtk.StyleContext main_context = get_style_context ();
        main_context.add_class ("quickfind-item");

        var main_grid = new Gtk.Grid () {
            column_spacing = 6,
            margin = 3
        };

        if (base_object is Objects.Project) {
            Objects.Project project = ((Objects.Project) base_object);

            var icon_project = new Widgets.IconColorProject (16);
            icon_project.project = project;

            var name_label = new Gtk.Label (markup_string_with_search (project.name, pattern)) {
                ellipsize = Pango.EllipsizeMode.END,
                xalign = 0,
                use_markup = true
            };

            main_grid.add (icon_project);
            main_grid.add (name_label);
        } else if (base_object is Objects.Item) {
            Objects.Item item = ((Objects.Item) base_object);

            var checked_button = new Gtk.CheckButton () {
                valign = Gtk.Align.CENTER
            };
            checked_button.get_style_context ().add_class ("priority-color");
            Util.get_default ().set_widget_priority (item.priority, checked_button);

            var content_label = new Gtk.Label (markup_string_with_search (item.content, pattern)) {
                ellipsize = Pango.EllipsizeMode.END,
                xalign = 0,
                use_markup = true
            };

            var project_label = new Gtk.Label (item.project.name) {
                ellipsize = Pango.EllipsizeMode.END,
                xalign = 0
            };

            project_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
            project_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

            main_grid.attach (checked_button, 0, 0, 1, 2);
            main_grid.attach (content_label, 1, 0, 1, 1);
            main_grid.attach (project_label, 1, 1, 1, 1);
        } else if (base_object is Objects.Label) {
            Objects.Label label = ((Objects.Label) base_object);

            var widget_color = new Gtk.Grid () {
                valign = Gtk.Align.CENTER,
                height_request = 12,
                width_request = 12
            };
    
            unowned Gtk.StyleContext widget_color_context = widget_color.get_style_context ();
            widget_color_context.add_class ("label-color");
            Util.get_default ().set_widget_color (Util.get_default ().get_color (label.color), widget_color);

            var name_label = new Gtk.Label (markup_string_with_search (label.name, pattern)) {
                ellipsize = Pango.EllipsizeMode.END,
                xalign = 0,
                use_markup = true
            };

            main_grid.add (widget_color);
            main_grid.add (name_label);
        } else if (base_object is Objects.Today || base_object is Objects.Scheduled ||
            base_object is Objects.Pinboard) {

            var filter_icon = new Gtk.Image () {
                gicon = new ThemedIcon (base_object.icon_name),
                pixel_size = 16,
                valign = Gtk.Align.CENTER,
                halign = Gtk.Align.CENTER
            };

            var name_label = new Gtk.Label (markup_string_with_search (base_object.name, pattern)) {
                ellipsize = Pango.EllipsizeMode.END,
                xalign = 0,
                use_markup = true
            };

            main_grid.add (filter_icon);
            main_grid.add (name_label);
        }

        add (main_grid);
    }

    private static string markup_string_with_search (string text, string pattern) {
        const string MARKUP = "%s";

        if (pattern == "") {
            return MARKUP.printf (Markup.escape_text (text));
        }

        // if no text found, use pattern
        if (text == "") {
            return MARKUP.printf (Markup.escape_text (pattern));
        }

        var matchers = Synapse.Query.get_matchers_for_query (
            pattern,
            0,
            RegexCompileFlags.OPTIMIZE | RegexCompileFlags.CASELESS
        );

        string? highlighted = null;
        foreach (var matcher in matchers) {
            MatchInfo mi;
            if (matcher.key.match (text, 0, out mi)) {
                int start_pos;
                int end_pos;
                int last_pos = 0;
                int cnt = mi.get_match_count ();
                StringBuilder res = new StringBuilder ();
                for (int i = 1; i < cnt; i++) {
                    mi.fetch_pos (i, out start_pos, out end_pos);
                    warn_if_fail (start_pos >= 0 && end_pos >= 0);
                    res.append (Markup.escape_text (text.substring (last_pos, start_pos - last_pos)));
                    last_pos = end_pos;
                    res.append (Markup.printf_escaped ("<b>%s</b>", mi.fetch (i)));
                    if (i == cnt - 1) {
                        res.append (Markup.escape_text (text.substring (last_pos)));
                    }
                }
                highlighted = res.str;
                break;
            }
        }

        if (highlighted != null) {
            return MARKUP.printf (highlighted);
        } else {
            return MARKUP.printf (Markup.escape_text (text));
        }
    }
}