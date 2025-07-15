import flet as ft
import uuid
from datetime import datetime
from models import persistence
from views import animal_detail_view

class AnimalController:
    def __init__(self, main_controller):
        self.main = main_controller
        self.page = main_controller.page
        self.app_state = main_controller.app_state
        
        self.herd_list_view = None
        self.animal_form_fields = {}
        self.history_form_fields = {}
        
        self.detail_content_area = ft.Container(expand=True)
        self.current_animal_id = None

    def handle_nav_bar_change(self, e):
        """Troca o conteúdo da página de detalhes com base no item da nav bar clicado."""
        selected_index = e.control.selected_index
        if selected_index == 0:
            self.update_detail_content("ficha")
        elif selected_index == 1:
            self.update_detail_content("pesagens")
        elif selected_index == 2:
            self.update_detail_content("vacinas")
        elif selected_index == 3:
            self.update_detail_content("ocorrencias")

    def update_detail_content(self, content_key: str):
        """Busca o animal e atualiza a área de conteúdo da view."""
        animal_data, _ = self.app_state.get_animal_by_id(self.current_animal_id)
        if not animal_data:
            self.detail_content_area.content = ft.Text("Animal não encontrado.")
        else:
            if content_key == "ficha":
                self.detail_content_area.content = animal_detail_view._build_ficha_content(self.main, animal_data)
            elif content_key == "pesagens":
                self.detail_content_area.content = animal_detail_view._build_pesagens_content(self.main, animal_data)
            elif content_key == "vacinas":
                self.detail_content_area.content = animal_detail_view._build_vacinas_section(self.main, animal_data)
            elif content_key == "ocorrencias":
                self.detail_content_area.content = animal_detail_view._build_doencas_section(self.main, animal_data)
        
        if self.page:
            self.page.update()

    def get_new_animal_template(self):
        return {
            "id": str(uuid.uuid4()),
            "brinco_interno": "",
            "nome": "",
            "data_nascimento": "",
            "raca": "",
            "sexo": "Fêmea",
            "lote_atual": "",
            "status_animal": "Ativo",
            "id_mae": "",
            "id_pai": "",
            "historico_pesagens": [],
            "historico_vacinacao": [],
            "historico_doencas": [],
        }

    def handle_save_animal(self, animal_id: str | None):
        form_data = {key: field.value for key, field in self.animal_form_fields.items()}
        
        if not form_data.get("brinco_interno"):
            self.animal_form_fields["brinco_interno"].error_text = "O brinco é obrigatório."
            self.page.update()
            return
        
        if animal_id:
            animal, _ = self.app_state.get_animal_by_id(animal_id)
            if animal:
                updated_animal = {**animal, **form_data}
                self.app_state.update_animal_by_id(animal_id, updated_animal)
                msg = f"Ficha do animal {form_data['brinco_interno']} atualizada."
        else:
            new_animal = self.get_new_animal_template()
            new_animal.update(form_data)
            self.app_state.add_animal(new_animal)
            msg = f"Animal {form_data['brinco_interno']} adicionado ao rebanho."

        persistence.save_state(self.app_state)
        self.page.open(ft.SnackBar(ft.Text(msg)))
        self.page.go("/herd")

    def handle_delete_animal(self, animal_id: str):
        self.app_state.delete_animal_by_id(animal_id)
        persistence.save_state(self.app_state)
        self.page.open(ft.SnackBar(ft.Text("Animal removido do rebanho.")))
        self.page.go("/herd")

    def handle_save_history_record(self, animal_id: str, history_key: str, record_data: dict, record_id: str | None):
        animal, _ = self.app_state.get_animal_by_id(animal_id)
        if not animal: return

        if record_id:
            history_list = animal.get(history_key, [])
            for i, rec in enumerate(history_list):
                if rec.get("id") == record_id:
                    history_list[i].update(record_data)
                    msg = "Registro atualizado com sucesso!"
                    break
        else:
            record_data["id"] = str(uuid.uuid4())
            record_data["data"] = datetime.now().strftime("%d/%m/%Y")
            animal[history_key].insert(0, record_data)
            msg = "Registro adicionado com sucesso!"

        self.app_state.update_animal_by_id(animal_id, animal)
        persistence.save_state(self.app_state)
        
        self.page.go(f"/animal/view/{animal_id}")
        self.page.open(ft.SnackBar(ft.Text(msg)))

    def handle_delete_history_record(self, animal_id: str, history_key: str, record_id: str):
        animal, _ = self.app_state.get_animal_by_id(animal_id)
        if not animal: return

        history_list = animal.get(history_key, [])
        animal[history_key] = [rec for rec in history_list if rec.get("id") != record_id]

        self.app_state.update_animal_by_id(animal_id, animal)
        persistence.save_state(self.app_state)

        self.page.go(f"/animal/view/{animal_id}")
        self.page.open(ft.SnackBar(ft.Text("Registro excluído.")))

    def update_herd_list(self, query: str = ""):
        if not self.herd_list_view: return
        from views import herd_list_view

        query = query.lower().strip()
        
        filtered_herd = sorted(
            [
                animal for animal in self.app_state.herd 
                if not query or 
                query in animal.get("brinco_interno", "").lower() or
                query in animal.get("nome", "").lower() or
                query in animal.get("lote_atual", "").lower()
            ],
            key=lambda x: x.get("brinco_interno", "")
        )

        self.herd_list_view.controls = [
            herd_list_view.create_animal_list_item(self.main, animal) 
            for animal in filtered_herd
        ]
        if not filtered_herd and not self.app_state.herd:
             self.herd_list_view.controls.append(
                ft.Column(
                    [
                        ft.Icon(ft.Icons.PETS, size=60, opacity=0.3),
                        ft.Text("Nenhum animal cadastrado.", size=18, weight=ft.FontWeight.BOLD),
                        ft.Text("Clique no botão '+' para adicionar o primeiro.", text_align=ft.TextAlign.CENTER),
                    ],
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    spacing=10,
                    expand=True,
                    alignment=ft.MainAxisAlignment.CENTER
                )
            )

        if self.herd_list_view.page:
            self.herd_list_view.update()

    def handle_filter_herd(self, e):
        self.update_herd_list(e.control.value)