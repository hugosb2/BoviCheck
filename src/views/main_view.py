import flet as ft
from models.definitions import APPBAR_SHORT_NAMES

class MainView:
    def __init__(self, controller):
        self.controller = controller
        self.page = controller.page
        self.page.drawer = self._create_navigation_drawer()

        self.restore_file_picker = ft.FilePicker(on_result=self.controller.handle_restore_file_picked)
        self.page.overlay.append(self.restore_file_picker)

    def _create_navigation_drawer(self) -> ft.NavigationDrawer:
        ai_enabled = self.controller.app_state.ai_settings.get("enabled", False)

        return ft.NavigationDrawer(
            on_change=self.controller.handle_nav_drawer_change,
            controls=[
                ft.ListTile(
                    title=ft.Text(
                        "Menu Principal",
                        size=20,
                        weight=ft.FontWeight.BOLD,
                        color="primary"
                    ),
                    dense=True,
                    disabled=True,
                    content_padding=ft.padding.only(left=16, top=12, bottom=8)
                ),
                ft.Divider(),

                ft.NavigationDrawerDestination(
                    icon=ft.Icon(ft.Icons.DASHBOARD_OUTLINED, color="primary"),
                    label="Dashboard"
                ),
                ft.NavigationDrawerDestination(
                    icon=ft.Icon(ft.Icons.TRENDING_UP_OUTLINED, color="primary"),
                    label="Índices"
                ),
                ft.NavigationDrawerDestination(
                    icon=ft.Icon(ft.Icons.CHAT_BUBBLE_OUTLINE_ROUNDED, color="primary"),
                    label="Histórico do Chat",
                    disabled=not ai_enabled
                ),
                ft.Divider(),
                ft.NavigationDrawerDestination(
                    icon=ft.Icon(ft.Icons.SETTINGS_OUTLINED, color="primary"),
                    label="Configurações"
                ),
                ft.NavigationDrawerDestination(
                    icon=ft.Icon(ft.Icons.INFO_OUTLINE, color="primary"),
                    label="Sobre"
                ),
                ft.Divider(),
                ft.NavigationDrawerDestination(
                    icon=ft.Icon(ft.Icons.EXIT_TO_APP_ROUNDED, color="primary"),
                    label="Sair"
                ),
            ]
        )

    def rebuild_drawer(self):
        self.page.drawer = self._create_navigation_drawer()
        self.page.update()

    def open_drawer(self, e):
        self.page.drawer.open = True
        self.page.update()

    def create_app_bar(self, title: str, show_back_button: bool = False) -> ft.AppBar:
        leading_icon = ft.IconButton(
            ft.Icons.ARROW_BACK_IOS_NEW_ROUNDED, on_click=self.controller.go_back,
            tooltip="Voltar",
            icon_color="onPrimary"
        ) if show_back_button else ft.IconButton(
            ft.Icons.MENU_ROUNDED,
            on_click=self.open_drawer,
            tooltip="Menu",
            icon_color="onPrimary"
        )

        return ft.AppBar(
            leading=leading_icon,
            title=ft.Text(
                title,
                weight=ft.FontWeight.BOLD,
                color="onPrimary"
            ),
            bgcolor="primary",
            center_title=False,
            elevation=2,
            actions=[]
        )