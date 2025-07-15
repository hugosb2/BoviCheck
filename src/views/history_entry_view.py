import flet as ft

FORMS_CONFIG = {
    "historico_pesagens": {
        "title_add": "Registrar Nova Pesagem",
        "title_edit": "Editar Pesagem",
        "fields": [
            {"key": "peso", "label": "Peso (kg)", "type": ft.KeyboardType.NUMBER},
        ]
    },
    "historico_vacinacao": {
        "title_add": "Registrar Nova Aplicação",
        "title_edit": "Editar Aplicação",
        "fields": [
            {"key": "vacina", "label": "Nome da Vacina/Produto"},
            {"key": "dose", "label": "Dose Aplicada"},
        ]
    },
    "historico_doencas": {
        "title_add": "Registrar Nova Ocorrência",
        "title_edit": "Editar Ocorrência",
        "fields": [
            {"key": "doenca", "label": "Doença/Ocorrência"},
            {"key": "tratamento", "label": "Tratamento Realizado"},
        ]
    }
}

def build_history_entry_view(controller, animal_id: str, history_key: str, record_id: str | None = None) -> ft.Container:
    animal_controller = controller.animal_controller
    is_editing = record_id is not None
    
    config = FORMS_CONFIG.get(history_key)
    if not config:
        return ft.Container(content=ft.Text(f"Erro: Formulário para '{history_key}' não encontrado."))

    title = config["title_edit"] if is_editing else config["title_add"]
    
    existing_data = {}
    if is_editing:
        animal, _ = controller.app_state.get_animal_by_id(animal_id)
        history_list = animal.get(history_key, [])
        existing_data = next((rec for rec in history_list if rec.get("id") == record_id), {})

    form_fields = {}
    form_controls = []

    for field_config in config["fields"]:
        key = field_config["key"]
        control = ft.TextField(
            label=field_config["label"],
            value=existing_data.get(key, ""),
            keyboard_type=field_config.get("type", ft.KeyboardType.TEXT),
            border_color="outline",
            cursor_color="primary"
        )
        form_fields[key] = control
        form_controls.append(control)

    animal_controller.history_form_fields = form_fields

    def save_entry(e):
        record_data = {key: field.value for key, field in form_fields.items()}
        animal_controller.handle_save_history_record(animal_id, history_key, record_data, record_id)

    save_button = ft.FilledButton(
        text="Salvar Registro",
        icon=ft.Icons.SAVE_OUTLINED,
        on_click=save_entry
    )

    return ft.Container(
        content=ft.Column(
            controls=[
                ft.Text(title, size=22, weight=ft.FontWeight.BOLD),
                ft.Divider(height=15),
                *form_controls,
                ft.Row([save_button], alignment=ft.MainAxisAlignment.END)
            ],
            spacing=15
        ),
        padding=20,
        expand=True
    )