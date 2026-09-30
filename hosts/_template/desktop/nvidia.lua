-- -----------------------------------------------------
-- NVIDIA DRIVER CONFIGURATION (DESKTOP TEMPLATE)
-- -----------------------------------------------------
-- For desktop PCs with dedicated NVIDIA GPUs driving all display outputs.

hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")

-- NOTE: Do NOT set GBM_BACKEND="nvidia-drm" on modern Hyprland/Aquamarine (causes black screens).

hl.config({
    cursor = {
        no_hardware_cursors = false,
    },
})

