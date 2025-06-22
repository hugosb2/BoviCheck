import flet as ft
from datetime import datetime
from models import persistence, export_manager

class DataController:
    def __init__(self, main_controller):
        self.main = main_controller
        self.page = main_controller.page
        self.app_state = main_controller.app_state
        self.file_manager = main_controller.file_manager_controller

        self.main.backup_checkboxes = {}
        self.main.spreadsheet_checkboxes = {}

    def handle_delete_all_data_confirmed(self, e):
        self.app_state.reset()
        persistence.save_state(self.app_state)
        self.page.open(ft.SnackBar(ft.Text("Todos os dados foram apagados.")))
        self.page.go("/dashboard")

    def handle_create_backup_click(self, e):
        selected_names = [name for name, cb in self.main.backup_checkboxes.items() if cb.value]
        if not selected_names:
            self.page.open(ft.SnackBar(ft.Text("Nenhum índice selecionado."), bgcolor=ft.Colors.AMBER))
            return

        backup_string = export_manager.backup_to_json_string(self.app_state.calculated_indices, selected_names)
        self.file_manager.data_to_save = backup_string
        self.file_manager.fm_initial_filename = f"bovicheck_backup_{datetime.now().strftime('%Y%m%d')}.json"
        self.page.go("/file_manager/save_data")

    def handle_export_spreadsheet_click(self, e):
        selected_names = [name for name, cb in self.main.spreadsheet_checkboxes.items() if cb.value]
        if not selected_names:
            self.page.open(ft.SnackBar(ft.Text("Nenhum índice selecionado."), bgcolor=ft.Colors.AMBER))
            return

        excel_bytes = export_manager.generate_spreadsheet_bytes(self.app_state.calculated_indices, selected_names)
        if excel_bytes:
            self.file_manager.data_to_save = excel_bytes
            self.file_manager.fm_initial_filename = f"bovicheck_planilha_{datetime.now().strftime('%Y%m%d')}.xlsx"
            self.page.go("/file_manager/save_data")
        else:
            self.page.open(ft.SnackBar(ft.Text("Erro ao gerar planilha. 'openpyxl' está instalado?"), bgcolor=ft.Colors.ERROR))

    def handle_select_restore_file_click(self, e):
        self.main.view.restore_file_picker.pick_files(
            dialog_title="Selecionar Arquivo de Backup (.json)",
            allow_multiple=False,
            allowed_extensions=["json"]
        )

    def handle_restore_file_picked(self, e: ft.FilePickerResultEvent):
        if not e.files:
            self.page.open(ft.SnackBar(ft.Text("Restauração cancelada.")))
            return

        try:
            with open(e.files[0].path, "r", encoding='utf-8') as f:
                json_string = f.read()
            success, message, restored_data = export_manager.restore_from_json_string(json_string)

            if success:
                items_added = 0
                for index_name, restored_calcs in restored_data.items():
                    if index_name not in self.app_state.calculated_indices:
                        self.app_state.calculated_indices[index_name] = []
                    existing_ids = {calc.get("id") for calc in self.app_state.calculated_indices[index_name]}
                    for calc_to_restore in restored_calcs:
                        if calc_to_restore.get("id") not in existing_ids:
                            self.app_state.calculated_indices[index_name].append(calc_to_restore)
                            existing_ids.add(calc_to_restore.get("id"))
                            items_added += 1
                persistence.save_state(self.app_state)
                final_message = f"Restauração concluída. {items_added} novo(s) registro(s) adicionado(s)."
                self.page.open(ft.SnackBar(ft.Text(final_message), bgcolor=ft.Colors.GREEN_700))
                self.page.go("/dashboard")
            else:
                self.page.open(ft.SnackBar(ft.Text(message), bgcolor=ft.Colors.ERROR))

        except Exception as ex:
            self.page.open(ft.SnackBar(ft.Text(f"Erro ao ler arquivo: {ex}"), bgcolor=ft.Colors.ERROR))