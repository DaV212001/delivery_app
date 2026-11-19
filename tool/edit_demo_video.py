import os
import subprocess

def edit_video():
    input_file = "recording.mp4"
    output_file = "clean_app_review_demo.mp4"
    
    # Filter to crop out Android status bar (top 58px) and ensure even dimensions
    # Original: 560x1280. Cropped: 560x1222. Scale to 560x1220 or 576x1280 if needed.
    # crop=560:1222:0:58,scale=560:1220
    crop_filter = "crop=560:1222:0:58,scale=560:1220"

    # Segments to extract (start_sec, end_sec, speed_multiplier)
    # 1. Splash & Onboarding start (0 to 6.5s)
    # 2. Skip permission popups (6.5s to 12.8s) -> Resume at 12.8s: Guest mode browsing (12.8 to 28.0s)
    # 3. Auth screen & switch between Sign Up / Log In (32.0 to 38.0s)
    # 4. Login submit & success (64.0 to 74.0s)
    # 5. Courier order creation & vehicle options (135.0 to 155.0s)
    # 6. Payment selection (Cash on Delivery) & Order Placed banner (185.0 to 208.0s)
    # 7. Profile -> Delete Account flow -> Confirmation modal -> Pending request (218.0 to 238.0s)
    
    segments = [
        (0.0, 6.2, 1.0),
        (13.0, 27.0, 1.2),
        (33.0, 38.0, 1.0),
        (64.5, 74.0, 1.2),
        (138.0, 155.0, 1.2),
        (188.0, 206.0, 1.2),
        (219.0, 238.0, 1.0),
    ]

    temp_clips = []
    os.makedirs("build/video_temp", exist_ok=True)
    
    for i, (start, end, speed) in enumerate(segments):
        duration = end - start
        clip_path = f"build/video_temp/clip_{i:02d}.mp4"
        temp_clips.append(clip_path)
        
        # If speed != 1.0, adjust video speed using setpts
        pts_factor = 1.0 / speed
        vf = f"{crop_filter},setpts={pts_factor}*PTS"
        
        cmd = [
            "ffmpeg", "-y",
            "-ss", str(start),
            "-t", str(duration),
            "-i", input_file,
            "-vf", vf,
            "-an", # Remove microphone/room audio for clean silence or review
            "-c:v", "libx264",
            "-preset", "fast",
            "-crf", "22",
            "-pix_fmt", "yuv420p",
            clip_path
        ]
        print(f"Rendering segment {i+1}/{len(segments)}: {start}s - {end}s (speed: {speed}x)...")
        res = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
        if res.returncode != 0:
            print(f"Error on clip {i}: {res.stderr}")
            return False

    # Concat all segments
    concat_list = "build/video_temp/concat_list.txt"
    with open(concat_list, "w") as f:
        for clip in temp_clips:
            # Use forward slashes
            f.write(f"file '{os.path.abspath(clip).replace(os.sep, '/')}'\n")

    print("Concatenating all segments into final review video...")
    concat_cmd = [
        "ffmpeg", "-y",
        "-f", "concat",
        "-safe", "0",
        "-i", concat_list,
        "-c", "copy",
        output_file
    ]
    res = subprocess.run(concat_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
    if res.returncode != 0:
        print(f"Concat error: {res.stderr}")
        return False

    print(f"Successfully generated: {output_file}")
    return True

if __name__ == "__main__":
    edit_video()
