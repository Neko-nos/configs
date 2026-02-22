# VScode

## launch.json
This is designed to be placed in each workspace and currently contains only Python debugging configurations.

## linebreak.py
In VSCode's `settings.json`, you can set `"markdown.preview.breaks": true`. While this allows line breaks to display correctly in the preview, they are not reflected in the code itself.<br>
Since typing `<br>` manually every time is tedious, I created a script that automatically inserts `<br>` to handle line breaks appropriately upon saving.<br>
It is implemented using only the Python standard library, so it works on the system Python.

> [!NOTE]
> Currently, Markdown files relying heavily on HTML are not supported.

### Run tests
From the repository root:

```console
uv run python -m unittest VSCode/test_linebreak.py
```

## settings.json
The `settings.json` for Ubuntu(and WSL).

## settings_mac.json
The `settings.json` for Mac.<br>
My main personal machine is a Mac and I also use it for writing other languages, so it includes more settings than the `settings.json` for Ubuntu/WSL.
