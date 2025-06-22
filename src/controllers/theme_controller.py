import flet as ft
from models import persistence

class ThemeController:
    def __init__(self, main_controller):
        self.main = main_controller
        self.page = main_controller.page
        self.app_state = main_controller.app_state

    def apply_initial_theme(self):
        prefs = self.app_state.theme_preference
        self.page.theme_mode = prefs.get("theme_mode", ft.ThemeMode.SYSTEM)
        color_name = prefs.get("primary_color_name", "TEAL_ACCENT_700")
        color_seed = getattr(ft.Colors, color_name, ft.Colors.TEAL_ACCENT_700)

        light_theme = ft.Theme(
            color_scheme_seed=color_seed,
            use_material3=True,
            font_family="OpenSans"
        )
        if light_theme.color_scheme:
            light_theme.color_scheme.background = ft.colors.blend_colors(
                [light_theme.color_scheme.background, color_seed], [0.9, 0.1]
            )
        self.page.theme = light_theme

        dark_theme = ft.Theme(
            color_scheme_seed=color_seed,
            use_material3=True,
            font_family="OpenSans",
            visual_density=ft.VisualDensity.COMPACT,
        )
        if dark_theme.color_scheme:
            dark_theme.color_scheme.primary = color_seed
            dark_theme.color_scheme.background = ft.colors.blend_colors(
                [ft.Colors.BLACK, color_seed], [0.85, 0.15]
            )
            dark_theme.color_scheme.surface = ft.colors.blend_colors(
                [ft.Colors.BLACK, color_seed], [0.8, 0.2]
            )
        self.page.dark_theme = dark_theme

    def handle_theme_mode_change(self, mode: ft.ThemeMode):
        self.page.theme_mode = mode
        self.app_state.theme_preference["theme_mode"] = mode
        persistence.save_state(self.app_state)
        self.page.update()
        self.main.go_back()

    def handle_theme_color_change(self, color_info: dict):
        self.app_state.theme_preference["primary_color_name"] = color_info["value"]
        self.apply_initial_theme()
        persistence.save_state(self.app_state)
        self.page.update()
        self.main.go_back()