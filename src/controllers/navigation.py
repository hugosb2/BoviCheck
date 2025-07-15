import flet as ft
from utils import helpers
from models import definitions

class Navigation:
    def __init__(self, controller):
        self.controller = controller
        self.page = controller.page

    def route_change_handler(self, route_event: ft.RouteChangeEvent):
        route = ft.TemplateRoute(route_event.route)

        if route.route == "/ai/chat":
            if not self.controller.app_state.chat_history:
                self.controller.start_new_chat()
            else:
                self.page.go("/ai/history")
            return

        is_top_level = route.route in ["/dashboard", "/indices", "/ai/history", "/settings/general", "/about"]

        current_chat = self.controller.app_state.get_current_chat()
        chat_title = current_chat['title'] if current_chat else "Chat com IA"
        app_bar_title = self.get_app_bar_title(route, chat_title)

        if is_top_level:
            self.page.views.clear()

        appbar = self.controller.view.create_app_bar(title=app_bar_title, show_back_button=not is_top_level)

        content = self.build_view_for_route(route)

        self.page.views.append(
            ft.View(
                route=route.route,
                controls=[content],
                appbar=appbar,
                drawer=self.page.drawer if is_top_level else None,
                padding=0
            )
        )
        self.sync_nav_drawer_to_route(route.route)
        self.page.update()

    def view_pop_handler(self, view_pop_event: ft.ViewPopEvent):
        self.page.views.pop()
        if self.page.views:
            top_view = self.page.views[-1]
            self.page.go(top_view.route)
        else:
            self.page.go("/dashboard")

    def build_view_for_route(self, route: ft.TemplateRoute) -> ft.Control:
        from views import (
            dashboard_view, indices_list_view, index_view, history_view,
            about_view, ai_view, settings_view, dialogs_view, export_view,
            file_manager_view, ai_history_view
        )

        if route.match("/dashboard"):
            return dashboard_view.build_dashboard_view(self.controller)
        if route.match("/indices"):
            return indices_list_view.build_indices_list_view(self.controller)
        if route.match("/index/:name/calculate"):
            name = helpers.from_safe_route_param(route.name)
            return index_view.build_index_calculation_view(self.controller, name, None)
        if route.match("/index/:name/edit/:calc_id"):
            name = helpers.from_safe_route_param(route.name)
            return index_view.build_index_calculation_view(self.controller, name, route.calc_id)
        if route.match("/index/:name/history"):
            name = helpers.from_safe_route_param(route.name)
            return history_view.build_index_history_view(self.controller, name)
        if route.match("/index/:name/delete_all_confirm"):
            name = helpers.from_safe_route_param(route.name)
            return dialogs_view.create_confirm_delete_index_calc_view(self.controller, name)
        if route.match("/index/:name/delete_single/:calc_id/confirm"):
            name = helpers.from_safe_route_param(route.name)
            return dialogs_view.create_confirm_delete_single_calc_view(self.controller, name, route.calc_id)

        if route.match("/ai/history"):
            return ai_history_view.build_ai_history_view(self.controller)
        if route.match("/ai/chat/:chat_id"):
            return ai_view.build_ai_chat_view(self.controller, route.chat_id)
        if route.match("/ai/chat/delete/:chat_id/confirm"):
            return dialogs_view.create_confirm_delete_chat_view(self.controller, route.chat_id)

        if route.match("/ai/settings"):
            return ai_view.build_ai_settings_view(self.controller)
        if route.match("/settings/general"):
            return settings_view.build_general_settings_view(self.controller)
        if route.match("/settings/theme_mode"):
            return settings_view.build_theme_mode_view(self.controller)
        if route.match("/settings/theme_color"):
            return settings_view.build_theme_color_view(self.controller)
        if route.match("/settings/delete_all_data"):
            return dialogs_view.create_confirm_delete_all_data_view(self.controller)
        if route.match("/settings/backup_indices"):
            return export_view.build_backup_indices_view(self.controller)
        if route.match("/settings/restore_indices"):
            return export_view.build_restore_indices_view(self.controller)
        if route.match("/settings/export_spreadsheet"):
            return export_view.build_export_spreadsheet_view(self.controller)
        if route.match("/settings/export_pdf"):
            return export_view.build_export_pdf_view(self.controller)
        if route.match("/file_manager/save_data"):
            return file_manager_view.build_file_manager_view(self.controller)
        if route.match("/about"):
            return about_view.build_about_view(self.controller)

        return ft.Text("Página não encontrada")

    def get_app_bar_title(self, route: ft.TemplateRoute, chat_title: str) -> str:
        index_routes = [
            "/index/:name/history",
            "/index/:name/calculate",
            "/index/:name/edit/:calc_id",
            "/index/:name/delete_all_confirm",
            "/index/:name/delete_single/:calc_id/confirm"
        ]
        
        for index_route in index_routes:
            if route.match(index_route):
                return helpers.from_safe_route_param(route.name)

        if route.match("/dashboard"): return "Dashboard Principal"
        if route.match("/indices"): return "Índices Zootécnicos"
        if route.match("/about"): return "Sobre o BoviCheck"
        
        if route.match("/ai/history"): return "Histórico do Chat"
        if route.match("/ai/chat/:chat_id"): return chat_title
        if route.match("/ai/chat/delete/:chat_id/confirm"): return "Apagar Conversa"

        if route.match("/settings/general"): return "Configurações Gerais"
        if route.match("/settings/backup_indices"): return "Backup de Dados"
        if route.match("/settings/restore_indices"): return "Restaurar Dados"
        if route.match("/settings/export_spreadsheet"): return "Exportar Planilha"
        if route.match("/settings/export_pdf"): return "Exportar Relatório PDF"
        if route.match("/settings/theme_mode"): return "Modo de Tema"
        if route.match("/settings/theme_color"): return "Cor do Tema"
        if route.match("/ai/settings"): return "Configurações de IA"
        if route.match("/settings/delete_all_data"): return "Apagar Dados"

        return "BoviCheck"

    def sync_nav_drawer_to_route(self, route_str: str):
        idx = -1
        if route_str == "/dashboard": idx = 0
        elif route_str.startswith("/indices") or route_str.startswith("/index/"): idx = 1
        elif route_str.startswith("/ai/"): idx = 2
        elif route_str.startswith("/settings/"): idx = 3
        elif route_str == "/about": idx = 4

        if self.page.drawer and self.page.drawer.selected_index != idx:
            self.page.drawer.selected_index = idx