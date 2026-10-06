// Screenshot.qml
// takes screenshots of the focused monitor, the active window or a selected region
// the image is saved to ~/Pictures/Screenshots and copied to the clipboard
// call with `qs ipc call screenshot screen|window|region`
import Quickshell
import Quickshell.Io

Scope {
	// $1 is the mode, $2 the delay so menus can close before capturing
	readonly property string script: `
		sleep "$2"
		dir="\${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
		mkdir -p "$dir"
		file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
		case "$1" in
		screen)
			grim -o "$(hyprctl -j activeworkspace | jq -r .monitor)" "$file" ;;
		window)
			geometry=$(hyprctl -j activewindow | jq -r 'select(.at) | "\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])"')
			[ -n "$geometry" ] || exit 0
			grim -g "$geometry" "$file" ;;
		region)
			geometry=$(slurp) || exit 0
			grim -g "$geometry" "$file" ;;
		esac || exit 1
		wl-copy --type image/png < "$file"
		notify-send -a Screenshot -i "$file" "Screenshot copied to clipboard" "Saved to $file"
	`

	function take(mode: string, delay: real): void {
		Quickshell.execDetached(["sh", "-c", script, "screenshot", mode, String(delay)])
	}

	IpcHandler {
		target: "screenshot"
		function screen(): void { take("screen", 0) }
		function window(): void { take("window", 0) }
		function region(): void { take("region", 0) }
		// used by the bar menu, waits for the menu to close first
		function screenDelayed(): void { take("screen", 0.3) }
		function windowDelayed(): void { take("window", 0.3) }
		function regionDelayed(): void { take("region", 0.3) }
	}
}
