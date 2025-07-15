import flet as ft

def build_herd_list_view(controller) -> ft.Column:
    animal_controller = controller.animal_controller
    
    search_bar = ft.TextField(
        hint_text="Pesquisar por brinco, nome ou lote...",
        on_change=animal_controller.handle_filter_herd,
        prefix_icon=ft.Icons.SEARCH,
        border_radius=30,
        height=45,
        content_padding=10,
        border_color="outline",
        focused_border_color="primary",
        cursor_color="primary",
    )

    animal_controller.herd_list_view = ft.ListView(expand=True, spacing=8, padding=8)
    animal_controller.update_herd_list()

    return ft.Column(
        controls=[
            ft.Container(
                content=search_bar,
                padding=ft.padding.symmetric(horizontal=10, vertical=8)
            ),
            ft.Divider(height=1),
            animal_controller.herd_list_view,
        ],
        expand=True
    )

def create_animal_list_item(controller, animal_data: dict) -> ft.Card:
    animal_id = animal_data["id"]
    
    icon = ft.Icon(ft.Icons.FEMALE, color="pink") if animal_data.get("sexo") == "Fêmea" else ft.Icon(ft.Icons.MALE, color="blue")

    return ft.Card(
        content=ft.ListTile(
            leading=icon,
            title=ft.Text(f"Brinco: {animal_data.get('brinco_interno', 'N/A')}", weight=ft.FontWeight.BOLD),
            subtitle=ft.Text(f"Raça: {animal_data.get('raca', 'N/A')} | Lote: {animal_data.get('lote_atual', 'N/A')}"),
            trailing=ft.Icon(ft.Icons.ARROW_FORWARD_IOS_ROUNDED),
            on_click=lambda _, r=animal_id: controller.page.go(f"/animal/view/{r}"),
        ),
        elevation=1.5
    )