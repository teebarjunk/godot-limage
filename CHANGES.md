# Changes

0.3
- `kra` support added.
- Lot's of rewriting. Works more in line with Godot now.

0.2.3
- Added `padding` to settings.
- Added `copy` tag.
- Added `dir` tag.
- Added `keep_data` tag.
- Added setting `keep_data`.
- Added build toggles *force update* to force build to happen, and *skip images* to only update data.
- Made PNG the default image export format.
- Setting an origin sets for all children as well, making texture offsets easier.
- Origin names can include *-* to apply to a child.

0.2.2
- Added `node` tag.
- LimageNode now properly uses local coordinates, so it can be a child, rotated, scaled, without problems.
- LimageNode `options` and `toggles` fields now work in editor more stabily.
- LimageNode `toggles` initial visibility is fixed.

0.2.1
- Editor should reload files properly now.

0.2
- Saving + loading should work better on Windows.
- Fixed `merge` tag still generating child textures.
- Fixed JPEG error because of no alpha channel.
- Fixed polygon generation not working with some image formats.
- If settings file is changed, image will be rebuilt.
 
