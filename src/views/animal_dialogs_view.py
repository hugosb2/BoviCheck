import flet as ft

def build_confirm_delete_history_view(controller, animal_id: str, history_key: str, record_id: str) -> ft.Container:
    animal_controller = controller.animal_controller
    
    animal, _ = controller.app_state.get_animal_by_id(animal_id)
    history_list = animal.get(history_key, [])
    record_to_delete = next((rec for rec in history_list if rec.get("id") == record_id), None)
    
    if not record_to_delete:
        return ft.Container(content=ft.Text("Erro: Registro não encontrado."))

    if history_key == "historico_pesagens":
        record_repr = f"Pesagem de {record_to_delete.get('peso')} kg em {record_to_delete.get('data')}"
    elif history_key == "historico_vacinacao":
        record_repr = f"Aplicação de {record_to_delete.get('vacina')} em {record_to_delete.get('data')}"
    else:
        record_repr = f"Ocorrência de {record_to_delete.get('doenca')} em {record_to_delete.get('data')}"


    delete_button_style = ft.ButtonStyle(bgcolor="error", color="onError")
    content_column = ft.Column(
        [
            ft.Icon(name=ft.Icons.DELETE_OUTLINE_ROUNDED, color="error", size=40),
            ft.Text("Excluir este registro?", size=18, weight=ft.FontWeight.BOLD),
            ft.Text(record_repr, text_align=ft.TextAlign.CENTER),
            ft.Text("Esta ação não pode ser desfeita.", size=12, text_align=ft.TextAlign.CENTER),
            ft.Row(
                [
                    ft.TextButton("Cancelar", on_click=controller.go_back),
                    ft.FilledButton(
                        "Excluir",
                        on_click=lambda e: animal_controller.handle_delete_history_record(animal_id, history_key, record_id),
                        style=delete_button_style
                    ),
                ],
                alignment=ft.MainAxisAlignment.CENTER
            )
        ],
        spacing=15, horizontal_alignment=ft.CrossAxisAlignment.CENTER
    )
    return ft.Container(
        content=ft.Card(ft.Container(content_column, padding=25)),
        alignment=ft.alignment.center, expand=True
    )