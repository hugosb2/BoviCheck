import flet as ft
from models.definitions import AVAILABLE_COLOR_SEEDS_WITH_NAMES

def build_general_settings_view(controller) -> ft.ListView:
    return ft.ListView(controls=[
            ft.ListTile(leading=ft.Icon(ft.Icons.SETTINGS_SUGGEST_OUTLINED, color="primary"), title=ft.Text("Configurações de IA"), subtitle=ft.Text("Habilitar IA e sugestões."), on_click=lambda _: controller.page.go("/ai/settings"), trailing=ft.Icon(ft.Icons.ARROW_FORWARD_IOS_ROUNDED)),
            ft.ListTile(leading=ft.Icon(ft.Icons.BRIGHTNESS_6_OUTLINED, color="primary"), title=ft.Text("Modo de Tema"), subtitle=ft.Text("Claro, escuro ou padrão do sistema."), on_click=lambda _: controller.page.go("/settings/theme_mode"), trailing=ft.Icon(ft.Icons.ARROW_FORWARD_IOS_ROUNDED)),
            ft.ListTile(leading=ft.Icon(ft.Icons.PALETTE_OUTLINED, color="primary"), title=ft.Text("Cor do Tema"), subtitle=ft.Text("Personalize a cor primária do aplicativo."), on_click=lambda _: controller.page.go("/settings/theme_color"), trailing=ft.Icon(ft.Icons.ARROW_FORWARD_IOS_ROUNDED)),
            
            ft.Divider(height=10),
            ft.ListTile(
                leading=ft.Icon(ft.Icons.UPLOAD_FILE_OUTLINED, color="primary"),
                title=ft.Text("Backup de Dados"),
                subtitle=ft.Text("Salvar dados dos índices em um arquivo .json."),
                on_click=lambda _: controller.page.go("/settings/backup_indices"),
                trailing=ft.Icon(ft.Icons.ARROW_FORWARD_IOS_ROUNDED)
            ),
            ft.ListTile(
                leading=ft.Icon(ft.Icons.DOWNLOAD_FOR_OFFLINE_OUTLINED, color="primary"),
                title=ft.Text("Restaurar Dados"),
                subtitle=ft.Text("Carregar dados de um arquivo de backup."),
                on_click=lambda _: controller.page.go("/settings/restore_indices"),
                trailing=ft.Icon(ft.Icons.ARROW_FORWARD_IOS_ROUNDED)
            ),
            ft.ListTile(
                leading=ft.Icon(ft.Icons.TABLE_CHART_OUTLINED, color="primary"),
                title=ft.Text("Exportar Planilha"),
                subtitle=ft.Text("Gerar um arquivo .xlsx com os resultados."),
                on_click=lambda _: controller.page.go("/settings/export_spreadsheet"),
                trailing=ft.Icon(ft.Icons.ARROW_FORWARD_IOS_ROUNDED)
            ),

            ft.Divider(height=10),
            ft.ListTile(leading=ft.Icon(ft.Icons.DELETE_SWEEP_OUTLINED, color=ft.Colors.ERROR), title=ft.Text("Apagar todos os dados", color=ft.Colors.ERROR), on_click=lambda _: controller.page.go("/settings/delete_all_data"), trailing=ft.Icon(ft.Icons.ARROW_FORWARD_IOS_ROUNDED, color=ft.Colors.ERROR)),
        ], spacing=5, padding=ft.padding.symmetric(vertical=10)
    )

def build_theme_mode_view(controller) -> ft.ListView:
    current_mode = controller.page.theme_mode
    modes = [{"name": "Claro", "mode": ft.ThemeMode.LIGHT, "icon": ft.Icons.LIGHT_MODE_OUTLINED}, {"name": "Escuro", "mode": ft.ThemeMode.DARK, "icon": ft.Icons.DARK_MODE_OUTLINED}, {"name": "Padrão do Sistema", "mode": ft.ThemeMode.SYSTEM, "icon": ft.Icons.SETTINGS_SUGGEST_OUTLINED}]
    items = []
    for mode_info in modes:
        is_selected = (current_mode == mode_info["mode"])
        items.append(ft.ListTile(title=ft.Text(mode_info["name"], weight=ft.FontWeight.BOLD if is_selected else ft.FontWeight.NORMAL), leading=ft.Icon(mode_info["icon"]), selected=is_selected, on_click=lambda _, m=mode_info["mode"]: controller.handle_theme_mode_change(m)))
    return ft.ListView(controls=items, expand=True, spacing=2)

def build_theme_color_view(controller) -> ft.ListView:
    current_color_name = controller.app_state.theme_preference.get("primary_color_name")
    items = []
    for color_info in AVAILABLE_COLOR_SEEDS_WITH_NAMES:
        is_selected = (current_color_name == color_info["value"])
        items.append(ft.ListTile(title=ft.Text(color_info["name"], weight=ft.FontWeight.BOLD if is_selected else ft.FontWeight.NORMAL), leading=ft.Icon(ft.Icons.CIRCLE, color=color_info["color_obj"]), selected=is_selected, on_click=lambda _, c=color_info: controller.handle_theme_color_change(c)))
    return ft.ListView(controls=items, expand=True, spacing=2)