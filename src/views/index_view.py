import flet as ft
import re

def build_index_calculation_view(controller, index_name: str, editing_calc_id: str | None) -> ft.Container:
    try:
        index_data = next(idx for idx in controller.get_all_indices() if idx["Índice"] == index_name)
    except StopIteration:
        return ft.Container(content=ft.Text(f"Erro: Índice '{index_name}' não encontrado."))

    is_editing = editing_calc_id is not None
    existing_values = []
    if is_editing:
        calc_to_edit, _ = controller.app_state.get_calculation_by_id(index_name, editing_calc_id)
        if calc_to_edit:
            existing_values = calc_to_edit.get("inputs", [])
        else:
            return ft.Container(content=ft.Text(f"Erro: Cálculo com ID '{editing_calc_id}' não encontrado."))

    concept_card = ft.Card(
        content=ft.Container(
            content=ft.Column([
                ft.Text("Conceito do Índice", weight=ft.FontWeight.BOLD),
                ft.Text(index_data["Conceito"], selectable=True),
            ]),
            padding=15
        ),
        elevation=1.5
    )

    input_fields = []
    input_descriptions = index_data["Inputs"].split(", ")
    for i, desc in enumerate(input_descriptions):
        is_date = index_data["Índice"] in ["Idade ao Primeiro Parto", "Intervalo entre Partos"] and i < 2
        value = str(existing_values[i]) if is_editing and i < len(existing_values) else ""
        field = _create_input_field(desc, is_date, value)
        input_fields.append(field)
    
    controller.current_input_fields = input_fields

    submit_button = ft.FilledButton(
        text="Atualizar Índice" if is_editing else "Calcular Índice",
        icon=ft.Icons.SAVE_AS_OUTLINED if is_editing else ft.Icons.CALCULATE_OUTLINED,
        on_click=lambda e: controller.handle_calculate_click(index_data, editing_calc_id),
        style=ft.ButtonStyle(padding=ft.padding.symmetric(vertical=12, horizontal=20))
    )

    inputs_card = ft.Card(
        content=ft.Container(
            content=ft.Column(
                [ft.Text("Entrada de Dados", weight=ft.FontWeight.BOLD)] +
                input_fields +
                [ft.Container(content=submit_button, alignment=ft.alignment.center, padding=ft.padding.only(top=20))]
            ),
            padding=15
        ),
        elevation=1.5
    )
    
    column_content = ft.Column(
        controls=[concept_card, inputs_card],
        spacing=10, 
        scroll=ft.ScrollMode.ADAPTIVE, 
        expand=True
    )

    return ft.Container(
        content=column_content,
        padding=10,
        expand=True
    )

def _create_input_field(label: str, is_date: bool, value: str) -> ft.TextField:
    return ft.TextField(
        label=label,
        value=value,
        keyboard_type=ft.KeyboardType.NUMBER,
        hint_text="DD/MM/AAAA" if is_date else "Insira o valor",
        border_radius=8,
        max_length=10 if is_date else None,
        border_color="outline",
        focused_border_color="primary",
        cursor_color="primary",
    )