-- -----------------------------------------------------
-- NVIDIA DRIVER CONFIGURATION (LAPTOP TEMPLATE)
-- -----------------------------------------------------
-- For hybrid laptops (AMD/Intel iGPU + NVIDIA dGPU):
-- Leave these variables commented out so the integrated GPU powers the display 
-- and handles video decoding, allowing the NVIDIA GPU to sleep and save battery.
-- Heavy 3D apps and games can be launched on-demand via `prime-run <command>`.

-- hl.env("LIBVA_DRIVER_NAME", "nvidia")
-- hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
-- hl.env("NVD_BACKEND", "direct")

-- NOTE: Do NOT set GBM_BACKEND="nvidia-drm" on modern Hyprland/Aquamarine (causes black screens).

hl.config({
    cursor = {
        no_hardware_cursors = false,
    },
})

