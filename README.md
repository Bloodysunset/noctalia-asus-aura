# ASUS Aura for Noctalia

A [Noctalia](https://github.com/noctalia-dev/noctalia) bar widget to control ASUS ROG keyboard lighting through [asusctl](https://gitlab.com/asus-linux/asusctl).

- **Left-click** the keyboard icon: pick the effect, speed, direction and colours. Changes apply immediately.
- **Right-click**: reapply the current effect (relights a keyboard that stayed dark).
- **After sleep**: the widget notices the resume and reapplies the effect a few seconds later, working around keyboards that come back unlit.

Only the effects your keyboard supports are listed (read from asusd's `/etc/asusd/aura_*.ron`).

> [!NOTE]
> This is an unofficial community project. It is not affiliated with, endorsed by, or supported by ASUSTeK Computer Inc. "ASUS", "ROG" and "Aura" are trademarks of their respective owners and are used here only to describe the hardware this plugin works with.

## Requirements

- Noctalia with plugin API 42 or newer
- `asusctl` with the `asusd` service running (`sudo systemctl enable --now asusd`)

## Install

Clone the repo and link it into Noctalia's local plugin folder:

```sh
git clone https://github.com/Bloodysunset/noctalia-asus-aura
ln -s "$PWD/noctalia-asus-aura" ~/.local/share/noctalia/plugins/asus_aura
noctalia msg plugins enable bloodysunset/asus_aura
```

Then add the **ASUS Aura** widget to a bar from Noctalia's settings.

To reload after editing the scripts:

```sh
noctalia msg plugins disable bloodysunset/asus_aura
noctalia msg plugins enable bloodysunset/asus_aura
```

## Files

| File          | Role                                                         |
| ------------- | ------------------------------------------------------------ |
| `plugin.toml` | Manifest: the bar widget and the panel                       |
| `aura.luau`   | Shared helpers: reads asusd's saved state, runs `asusctl`    |
| `widget.luau` | Bar icon, right-click reapply, resume detection              |
| `panel.luau`  | Effect / speed / direction / colour menu                     |

## License

MIT
