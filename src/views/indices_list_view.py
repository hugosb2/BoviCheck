import flet as ft

def build_indices_list_view(controller) -> ft.Column:
    controller.indices_search_bar = ft.TextField(
        hint_text="Pesquisar índice...",
        on_change=controller.handle_filter_indices,
        prefix_icon=ft.Icons.SEARCH,
        border_radius=30,
        height=45,
        content_padding=10,
        border_color="outline",
        focused_border_color="primary",
        cursor_color="primary",
    )

    controller.indices_list_view = ft.ListView(expand=True, spacing=5, padding=5)
    
    controller.update_indices_list()

    return ft.Column(
        controls=[
            ft.Container(
                content=controller.indices_search_bar,
                padding=ft.padding.symmetric(horizontal=10, vertical=8)
            ),
            ft.Divider(height=1),
            controller.indices_list_view,
        ],
        expand=True
    )

def create_index_list_item(controller, index_data: dict) -> ft.Card:
    safe_name = controller.to_safe_route(index_data["Índice"])

    icon_name = ft.Icons.TRENDING_UP
    if "Taxa" in index_data["Índice"]: icon_name = ft.Icons.PERCENT_OUTLINED
    elif "Peso" in index_data["Índice"]: icon_name = ft.Icons.SCALE_OUTLINED
    elif "Idade" in index_data["Índice"]: icon_name = ft.Icons.CALENDAR_MONTH_OUTLINED

    return ft.Card(
        content=ft.ListTile(
            leading=ft.Icon(icon_name, color="primary"),
            title=ft.Text(index_data["Índice"], weight=ft.FontWeight.BOLD),
            subtitle=ft.Text(index_data["Inputs"], max_lines=1, overflow=ft.TextOverflow.ELLIPSIS),
            trailing=ft.Icon(ft.Icons.ARROW_FORWARD_IOS_ROUNDED),
            on_click=lambda _, r=safe_name: controller.page.go(f"/index/{r}/calculate"),
        ),
        elevation=1.5
    )