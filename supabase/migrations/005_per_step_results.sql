-- Cache the Vision API output so re-processing can skip the Vision step.
-- The worker now checks: if transcript is non-null, skip Whisper; if
-- vision_result is non-null, skip Vision; if nlp_result is non-null, skip
-- NLP. Force any single step to re-run by NULLing its column and setting
-- status='queued'.

alter table public.tiktok_videos
  add column if not exists vision_result jsonb;
