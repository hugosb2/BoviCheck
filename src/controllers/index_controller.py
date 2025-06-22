import flet as ft
import re
from datetime import datetime
from models import definitions, persistence
from utils import helpers
from views import history_view

class IndexController:
    def __init__(self, main_controller):
        self.main = main_controller
        self.page = main_controller.page
        self.app_state = main_controller.app_state
        self.calculator = main_controller.calculator

        self.main.indices_search_bar = None
        self.main.indices_list_view = None
        self.main.current_input_fields = []
        self.main.history_details_container = None
        self.main.history_start_date_input = None
        self.main.history_end_date_input = None
        self.main.history_chart_container = None

    def get_all_indices(self):
        return definitions.INDICES

    def to_safe_route(self, name: str) -> str:
        return helpers.to_safe_route_param(name)

    def update_indices_list(self, query: str = ""):
        if not self.main.indices_list_view: return
        from views import indices_list_view

        all_indices = self.get_all_indices()
        query = query.lower().strip()
        filtered = [idx for idx in all_indices if not query or query in idx["Índice"].lower()]

        self.main.indices_list_view.controls = [indices_list_view.create_index_list_item(self.main, idx) for idx in filtered]
        if self.main.indices_list_view.page: self.main.indices_list_view.update()

    def handle_filter_indices(self, e):
        self.update_indices_list(e.control.value)

    def handle_calculate_click(self, index_data: dict, editing_id: str | None):
        values = [field.value.strip() for field in self.main.current_input_fields]
        for i, v in enumerate(values):
            if not v: self.main.current_input_fields[i].error_text = "Campo obrigatório"
            else: self.main.current_input_fields[i].error_text = None
        if any(f.error_text for f in self.main.current_input_fields):
            self.page.update(); return

        try:
            result_entry = self.calculator.calculate(index_data, values)
            msg = ""
            if editing_id:
                self.app_state.update_calculation_by_id(index_data["Índice"], editing_id, result_entry)
                msg = f"Índice '{index_data['Índice']}' atualizado!"
            else:
                self.app_state.add_new_calculation(index_data["Índice"], result_entry)
                msg = f"Índice '{index_data['Índice']}' calculado com sucesso!"

            persistence.save_state(self.app_state)
            self.page.open(ft.SnackBar(ft.Text(msg)))
            self.page.go(f"/index/{helpers.to_safe_route_param(index_data['Índice'])}/history")
        except (ValueError, NotImplementedError) as e:
            self.page.open(ft.SnackBar(ft.Text(f"Erro: {e}"), bgcolor=ft.Colors.ERROR_CONTAINER))

    def handle_history_item_selected(self, calc_data: dict, index_name: str):
        if not self.main.history_details_container: return
        from views.history_view import build_details_card

        details_card = build_details_card(self.main, calc_data, index_name)
        self.main.history_details_container.content = details_card
        self.main.history_details_container.update()

    def handle_delete_index_confirmed(self, index_name: str):
        if index_name in self.app_state.calculated_indices:
            del self.app_state.calculated_indices[index_name]
            persistence.save_state(self.app_state)
            self.page.open(ft.SnackBar(ft.Text(f"Histórico do índice '{index_name}' foi apagado.")))
        self.page.go("/dashboard")

    def handle_delete_single_calc_confirmed(self, index_name: str, calc_id: str):
        calc, index = self.app_state.get_calculation_by_id(index_name, calc_id)
        if calc is not None:
            self.app_state.calculated_indices[index_name].pop(index)
            if not self.app_state.calculated_indices[index_name]:
                del self.app_state.calculated_indices[index_name]
            persistence.save_state(self.app_state)
            self.page.open(ft.SnackBar(ft.Text("Medição excluída com sucesso.")))
        self.page.go(f"/index/{helpers.to_safe_route_param(index_name)}/history")
    
    def _validate_and_filter_history(self, index_name):
        start_date_str = self.main.history_start_date_input.value if self.main.history_start_date_input else ""
        end_date_str = self.main.history_end_date_input.value if self.main.history_end_date_input else ""

        def _validate(date_str):
            if not date_str or not re.match(r"^\d{2}/\d{2}/\d{4}$", date_str): return None
            try: return datetime.strptime(date_str, "%d/%m/%Y")
            except ValueError: return None
        
        start_date = _validate(start_date_str)
        end_date = _validate(end_date_str)

        self.main.history_start_date_input.error_text = "Inválida" if start_date_str and not start_date else None
        self.main.history_end_date_input.error_text = "Inválida" if end_date_str and not end_date else None
        
        if start_date and end_date and start_date > end_date:
            self.main.history_start_date_input.error_text = "Inicial > Final"

        self.main.history_start_date_input.update()
        self.main.history_end_date_input.update()

        if self.main.history_start_date_input.error_text or self.main.history_end_date_input.error_text:
            return None

        all_calcs = self.app_state.calculated_indices.get(index_name, [])
        if not (start_date and end_date):
            return all_calcs
        
        filtered = [
            calc for calc in all_calcs
            if start_date <= datetime.strptime(calc.get('Data', '01/01/1900'), "%d/%m/%Y") <= end_date
        ]
        return filtered

    def handle_apply_date_filter(self, e, index_name: str):
        if not self.main.history_chart_container: return

        filtered_calcs = self._validate_and_filter_history(index_name)
        
        if filtered_calcs is not None:
            sorted_calcs = sorted(
                filtered_calcs,
                key=lambda x: datetime.strptime(f"{x.get('Data','')} {x.get('Hora','')}", "%d/%m/%Y %H:%M"),
                reverse=True
            )
            new_chart = history_view._build_bar_chart(self.main, sorted_calcs, index_name)
            self.main.history_chart_container.content = new_chart
            self.main.history_chart_container.update()

    def handle_clear_date_filter(self, e, index_name: str):
        if self.main.history_start_date_input:
            self.main.history_start_date_input.value = ""
            self.main.history_start_date_input.error_text = None
            self.main.history_start_date_input.update()
        if self.main.history_end_date_input:
            self.main.history_end_date_input.value = ""
            self.main.history_end_date_input.error_text = None
            self.main.history_end_date_input.update()

        if not self.main.history_chart_container: return
        all_calcs = self.app_state.calculated_indices.get(index_name, [])
        sorted_calcs = sorted(
            all_calcs,
            key=lambda x: datetime.strptime(f"{x.get('Data','')} {x.get('Hora','')}", "%d/%m/%Y %H:%M"),
            reverse=True
        )
        new_chart = history_view._build_bar_chart(self.main, sorted_calcs, index_name)
        self.main.history_chart_container.content = new_chart
        self.main.history_chart_container.update()

    def handle_date_input_change(self, e: ft.ControlEvent):
        field = e.control
        clean_text = "".join(filter(str.isdigit, field.value))
        
        new_text = ""
        if len(clean_text) > 0:
            new_text = clean_text[:2]
        if len(clean_text) > 2:
            new_text += "/" + clean_text[2:4]
        if len(clean_text) > 4:
            new_text += "/" + clean_text[4:8]

        if new_text != field.value:
            field.value = new_text
            field.update()