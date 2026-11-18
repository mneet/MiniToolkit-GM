// Prevent delta_time spikes
__delta_time = delta_time / 1000000;
__delta_time = __delta_time > max_delta_time ? max_delta_time : __delta_time;

var _count = array_length(tweens);
var _write_idx = 0;

for (var _i = 0; _i < _count; _i++)
{
    var _tween = tweens[_i];
    
    if (!_tween.__step(__delta_time * MINI_TWEEN_TIME_SCALE))
    {
        // Tween finished/destroyed
        continue;
    }
    
    // Keep tween
    tweens[_write_idx++] = _tween;
}

// Keep tweens created by callbacks during this step (appended after _count)
var _total = array_length(tweens);
for (var _i = _count; _i < _total; _i++)
{
    tweens[_write_idx++] = tweens[_i];
}

// Resize array to remove finished tweens
if (_write_idx < _total)
{
    array_resize(tweens, _write_idx);
}