import flet as ft
import os

from models import app_state, persistence, calculator, definitions
from views import main_view
from . import navigation
from .theme_controller import ThemeController
from .index_controller import IndexController
from .data_controller import DataController
from .ai_controller import AIController
from .file_manager_controller import FileManagerController

class MainController:
    def __init__(self, page: ft.Page):
        self.page = page
        self.app_state = app_state.AppState()
        persistence.load_state(self.app_state)

        self.calculator = calculator.IndexCalculator()
        self.view = main_view.MainView(self)
        self.navigation = navigation.Navigation(self)

        self.theme_controller = ThemeController(self)
        self.index_controller = IndexController(self)
        self.ai_controller = AIController(self)
        self.file_manager_controller = FileManagerController(self)
        self.data_controller = DataController(self)

        self.theme_controller.apply_initial_theme()

    def go_back(self, e=None):
        if len(self.page.views) > 1:
            self.page.views.pop()
            top_view = self.page.views[-1]
            self.page.go(top_view.route)

    def handle_nav_drawer_change(self, e):
        self.page.drawer.open = False
        routes = ["/dashboard", "/indices", "/ai/history", "/settings/general", "/about"]
        idx = int(e.data)
        if idx < len(routes):
            self.page.go(routes[idx])
        elif idx == 5:
            os._exit(0)
        self.page.update()

    def handle_theme_mode_change(self, mode: ft.ThemeMode):
        self.theme_controller.handle_theme_mode_change(mode)

    def handle_theme_color_change(self, color_info: dict):
        self.theme_controller.handle_theme_color_change(color_info)

    def get_all_indices(self):
        return self.index_controller.get_all_indices()

    def to_safe_route(self, name: str):
        return self.index_controller.to_safe_route(name)

    def update_indices_list(self, query: str = ""):
        self.index_controller.update_indices_list(query)

    def handle_filter_indices(self, e):
        self.index_controller.handle_filter_indices(e)

    def handle_calculate_click(self, index_data: dict, editing_id: str | None):
        self.index_controller.handle_calculate_click(index_data, editing_id)

    def handle_history_item_selected(self, calc_data: dict, index_name: str):
        self.index_controller.handle_history_item_selected(calc_data, index_name)

    def handle_delete_index_confirmed(self, index_name: str):
        self.index_controller.handle_delete_index_confirmed(index_name)

    def handle_delete_single_calc_confirmed(self, index_name: str, calc_id: str):
        self.index_controller.handle_delete_single_calc_confirmed(index_name, calc_id)
    
    def handle_apply_date_filter(self, e, index_name: str):
        self.index_controller.handle_apply_date_filter(e, index_name)

    def handle_clear_date_filter(self, e, index_name: str):
        self.index_controller.handle_clear_date_filter(e, index_name)

    def handle_date_input_change(self, e: ft.ControlEvent):
        self.index_controller.handle_date_input_change(e)

    def handle_delete_all_data_confirmed(self, e):
        self.data_controller.handle_delete_all_data_confirmed(e)

    def handle_create_backup_click(self, e):
        self.data_controller.handle_create_backup_click(e)

    def handle_export_spreadsheet_click(self, e):
        self.data_controller.handle_export_spreadsheet_click(e)

    def handle_export_pdf_click(self, e):
        self.data_controller.handle_export_pdf_click(e)

    def handle_select_restore_file_click(self, e):
        self.data_controller.handle_select_restore_file_click(e)

    def handle_restore_file_picked(self, e: ft.FilePickerResultEvent):
        self.data_controller.handle_restore_file_picked(e)

    def get_fm_display_path(self):
        return self.file_manager_controller.get_fm_display_path()

    def fm_populate_directory_listing(self):
        self.file_manager_controller.fm_populate_directory_listing()

    def fm_navigate_to_path(self, new_path: str):
        self.file_manager_controller.fm_navigate_to_path(new_path)

    def handle_fm_save_file(self, e):
        self.file_manager_controller.handle_fm_save_file(e)

    def handle_ai_enabled_change(self, e):
        self.ai_controller.handle_ai_enabled_change(e)

    def handle_ai_suggestions_change(self, e):
        self.ai_controller.handle_ai_suggestions_change(e)

    def start_new_chat(self, e=None, title: str | None = None, initial_messages: list | None = None):
        self.ai_controller.start_new_chat(e, title, initial_messages)

    def open_chat(self, chat_id: str):
        self.ai_controller.open_chat(chat_id)

    def handle_delete_chat_confirmed(self, chat_id: str):
        self.ai_controller.handle_delete_chat_confirmed(chat_id)

    def open_rename_dialog(self, e):
        self.ai_controller.open_rename_dialog(e)

    def confirm_chat_rename(self, e):
        self.ai_controller.confirm_chat_rename(e)

    def close_rename_dialog(self, e):
        self.ai_controller.close_rename_dialog(e)

    def handle_send_ai_chat_message(self, e):
        self.ai_controller.handle_send_ai_chat_message(e)

    def handle_dashboard_suggestion_click(self, e, text_control, loading_control, continue_button):
        self.ai_controller.handle_dashboard_suggestion_click(e, text_control, loading_control, continue_button)

    def handle_index_suggestion_click(self, e, text_control, loading_control, continue_button):
        self.ai_controller.handle_index_suggestion_click(e, text_control, loading_control, continue_button)

    def handle_continue_in_chat_click(self, e):
        self.ai_controller.handle_continue_in_chat_click(e)