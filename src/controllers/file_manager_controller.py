import flet as ft
import os
from flet_permission_handler import PermissionHandler, PermissionType

class FileManagerController:
    
    def __init__(self, main_controller):
        self.main = main_controller
        self.page = main_controller.page

        self.fm_current_path = os.path.expanduser("~") if os.name != 'posix' else "/storage/emulated/0"
        self.fm_path_display = None
        self.fm_directory_listing = None
        self.fm_filename_input = None
        self.fm_initial_filename = ""
        self.data_to_save = None

    def get_fm_display_path(self) -> str:
        max_len = 45
        path = self.fm_current_path
        return ("..." + path[-(max_len-3):]) if len(path) > max_len else path

    def fm_populate_directory_listing(self):
        if not self.fm_directory_listing: return
        self.fm_directory_listing.controls.clear()
        path = self.fm_current_path
        parent = os.path.dirname(path)
        if parent != path:
            self.fm_directory_listing.controls.append(
                ft.ListTile(
                    leading=ft.Icon(ft.Icons.ARROW_UPWARD, color=ft.Colors.AMBER),
                    title=ft.Text(".. (Voltar)"),
                    on_click=lambda _, p=parent: self.fm_navigate_to_path(p)
                )
            )
        try:
            for item in sorted(os.listdir(path)):
                full_path = os.path.join(path, item)
                if os.path.isdir(full_path):
                    self.fm_directory_listing.controls.append(
                        ft.ListTile(
                            leading=ft.Icon(ft.Icons.FOLDER),
                            title=ft.Text(item),
                            on_click=lambda _, p=full_path: self.fm_navigate_to_path(p)
                        )
                    )
        except Exception as e:
            self.fm_directory_listing.controls.append(ft.Text(f"Erro de acesso: {e}", color=ft.Colors.ERROR))
        if self.fm_directory_listing.page: self.fm_directory_listing.update()

    def fm_navigate_to_path(self, new_path: str):
        self.fm_current_path = os.path.abspath(new_path)
        if self.fm_path_display:
            self.fm_path_display.value = self.get_fm_display_path()
            self.fm_path_display.tooltip = self.fm_current_path
            self.fm_path_display.update()
        self.fm_populate_directory_listing()

    def handle_fm_save_file(self, e):
        filename = self.fm_filename_input.value.strip()
        if not filename:
            self.page.open(ft.SnackBar(ft.Text("Nome do arquivo não pode ser vazio."), bgcolor=ft.Colors.ERROR))
            return

        full_path = os.path.join(self.fm_current_path, filename)
        try:
            mode = "wb" if isinstance(self.data_to_save, bytes) else "w"
            with open(full_path, mode, encoding=None if mode == "wb" else "utf-8") as f:
                f.write(self.data_to_save)
            self.page.open(ft.SnackBar(ft.Text(f"Arquivo salvo com sucesso em: {full_path}"), bgcolor=ft.Colors.GREEN_700))
            self.data_to_save = None
            self.page.go("/dashboard")
        except Exception as ex:
            self.page.open(ft.SnackBar(ft.Text(f"Erro ao salvar arquivo: {ex}"), bgcolor=ft.Colors.ERROR))