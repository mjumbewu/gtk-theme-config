using Gtk;

public class Preferences : Dialog {

	private File gtk2_config_file;
	private File gtk3_config_file;

	private Entry color_value;
	private Widget apply_button;

	private string selected_bg_color;

	public Preferences () {

		this.title = "GTK theme preferences";
		this.border_width = 10;
		set_default_size (250, 300);

		// Set window icon
		try {
			this.icon = IconTheme.get_default ().load_icon ("preferences-desktop-wallpaper", 48, 0);
			} catch (Error e) {
			stderr.printf ("Could not load application icon: %s\n", e.message);
			}

		// Methods
		set_config();
		create_widgets ();
		connect_signals ();
	}

	private void set_config () {
		// Detect the theme name
		// var settings = new GLib.Settings ("org.gnome.desktop.interface");
		// var gtk_theme = settings.get_string ("gtk-theme");

		// Set the path of config file
		var gtk2_path = Path.build_filename (Environment.get_home_dir (),
									  ".gtkrc-2.0");
		var gtk3_path = Path.build_filename (Environment.get_user_config_dir (),
									  "gtk-3.0/gtk.css");
		gtk2_config_file = File.new_for_path (gtk2_path);
		gtk3_config_file = File.new_for_path (gtk3_path);
	}

	private void set_defaults () {

		// Set default config
		color_value.text = "#398ee7";
	}

	private void read_config () {

		// Read the config file
		if (gtk3_config_file.query_exists ()) {
			try {
				var dis = new DataInputStream (gtk3_config_file.read ());
				string line;
				while ((line = dis.read_line (null)) != null) {
					if ("@define-color selected_bg_color" in line) {
						color_value.text = line.substring (32, line.length-33);
					}
				}
			} catch (Error e) {
				stderr.printf ("%s", e.message);
			}
		} else {
			set_defaults();
		}
	}

	private void create_widgets () {

		// Create and setup widgets
		var description = new Gtk.Label ("Change GTK theme color");
		var color_label = new Label.with_mnemonic ("Color value:");
		this.color_value = new Entry ();

		// Layout widgets
		var hbox = new Box (Orientation.HORIZONTAL, 10);
		hbox.homogeneous = false;
		hbox.pack_start (color_label, true, true, 0);
		hbox.pack_start (this.color_value, true, true, 0);
		var content = get_content_area () as Box;
		content.pack_start (description, false, true, 0);
		content.pack_start (hbox, false, true, 0);
		content.spacing = 10;

		// Read config file and set values
		read_config();

		// Add buttons to button area at the bottom
		this.apply_button = add_button (Stock.APPLY, ResponseType.APPLY);
		this.apply_button.sensitive = false;
		add_button ("_Reset to defaults", ResponseType.ACCEPT);
		add_button (Stock.CLOSE, ResponseType.CLOSE);

		show_all ();
	}

	private void connect_signals () {
		color_value.changed.connect (() => {
			if ("#" in color_value.text || "rgb" in color_value.text) {
				this.apply_button.sensitive = true;
			}
		});
		this.response.connect (on_response);
	}

	private void on_response (Dialog source, int response_id) {
		switch (response_id) {
		case ResponseType.ACCEPT:
			set_defaults();
			on_set_clicked ();
			break;
		case ResponseType.APPLY:
			on_set_clicked ();
			break;
		case ResponseType.CLOSE:
			destroy ();
			break;
		}
	}

	private void on_set_clicked () {
		write_config ();
		try {
			Process.spawn_command_line_sync("notify-send \"Changes applied!\"");
		} catch (Error e) {
			stderr.printf ("%s", e.message);
		}
		this.apply_button.sensitive = false;
	}

	private void write_config () {
		if ("#" in color_value.text || "rgb" in color_value.text) {
			selected_bg_color = "%s".printf(color_value.text);
		}
		if (gtk2_config_file.query_exists ()) {
			try {
				gtk2_config_file.delete ();
			} catch (Error e) {
				stderr.printf ("%s", e.message);
			}
		}
		try {
			var dos = new DataOutputStream (gtk2_config_file.create (FileCreateFlags.REPLACE_DESTINATION));
			dos.put_string ("# GTK theme preferences\n");
			string text = "gtk_color_scheme = \"selected_bg_color:%s\"".printf(selected_bg_color);
			uint8[] data = text.data;
			long written = 0;
			while (written < data.length) {
				written += dos.write (data[written:data.length]);
			}
		} catch (Error e) {
			stderr.printf ("%s", e.message);
		}
		if (gtk3_config_file.query_exists ()) {
			try {
				gtk3_config_file.delete ();
			} catch (Error e) {
				stderr.printf ("%s", e.message);
			}
		}
		try {
			var dos = new DataOutputStream (gtk3_config_file.create (FileCreateFlags.REPLACE_DESTINATION));
			dos.put_string ("/* GTK theme preferences */\n");
			string text = "@define-color selected_bg_color %s;".printf(selected_bg_color);
			uint8[] data = text.data;
			long written = 0;
			while (written < data.length) {
				written += dos.write (data[written:data.length]);
			}
		} catch (Error e) {
			stderr.printf ("%s", e.message);
		}
	}
}

int main (string[] args) {
	Gtk.init (ref args);
	var dialog = new Preferences ();
	dialog.destroy.connect (Gtk.main_quit);
	dialog.show ();
	Gtk.main ();
	return 0;
}