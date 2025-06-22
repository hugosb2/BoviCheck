import flet as ft
import os

def build_file_manager_view(controller) -> ft.Container:
    fm_controller = controller.file_manager_controller

    fm_controller.fm_path_display = ft.Text(
        value=fm_controller.get_fm_display_path(), 
        expand=True, 
        tooltip=fm_controller.fm_current_path, 
        no_wrap=True
    )
    fm_controller.fm_directory_listing = ft.ListView(expand=True, spacing=1)
    
    fm_controller.fm_filename_input = ft.TextField(
        label="Nome do Arquivo", 
        value=fm_controller.fm_initial_filename, 
        expand=True, 
        height=45, 
        content_padding=10,
        border_color="outline",
        focused_border_color="primary",
        cursor_color="primary",
    )

    fm_controller.fm_populate_directory_listing()
    return ft.Container(
        content=ft.Column(controls=[
                ft.Row([
                    ft.IconButton(
                        icon=ft.Icons.ARROW_UPWARD_ROUNDED, 
                        tooltip="Ir para diretório pai", 
                        on_click=lambda _: fm_controller.fm_navigate_to_path(os.path.dirname(fm_controller.fm_current_path))
                    ),
                    fm_controller.fm_path_display,
                ], vertical_alignment=ft.CrossAxisAlignment.CENTER),
                ft.Divider(height=5),
                ft.Container(
                    content=fm_controller.fm_directory_listing, 
                    expand=True, 
                    border=ft.border.all(1, ft.Colors.with_opacity(0.3, ft.Colors.OUTLINE)), 
                    border_radius=8
                ),
                ft.Divider(height=5),
                ft.Row([fm_controller.fm_filename_input]),
                ft.Row([
                    ft.TextButton("Cancelar", on_click=controller.go_back), 
                    ft.FilledButton(
                        "Salvar Arquivo", 
                        icon=ft.Icons.SAVE_AS_OUTLINED, 
                        on_click=fm_controller.handle_fm_save_file
                    )
                ], alignment=ft.MainAxisAlignment.END)
            ], expand=True, spacing=8
        ), expand=True, padding=15
    )