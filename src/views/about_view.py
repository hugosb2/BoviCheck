import flet as ft
from models.definitions import VERSION_NUMBER, BUILD_TAG

def build_about_view(controller) -> ft.Container:
    primary_color = (controller.page.theme.color_scheme.primary if controller.page.theme and controller.page.theme.color_scheme else ft.Colors.PRIMARY)
    
    app_title_section = ft.Container(
        content=ft.Column([
                ft.Image(src="icontest.ico", width=56, height=56),
                ft.Text("BoviCheck", size=30, weight=ft.FontWeight.BOLD),
                ft.Text("Seu assistente para índices zootécnicos.", size=15, italic=True),
            ], horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=10,
        ), padding=ft.padding.only(top=20, bottom=25)
    )
    
    info_card = ft.Card(
        content=ft.Container(
            content=ft.Column([
                    ft.Row([ft.Icon(ft.Icons.INFO_OUTLINE), ft.Text("Informações", weight=ft.FontWeight.BOLD)]),
                    ft.Divider(height=5, thickness=0.5),
                    ft.Text(f"Versão: {VERSION_NUMBER} ({BUILD_TAG})"),
                    ft.Text(f"Desenvolvedor: Hugo Barros", size=14),
                    ft.Row([ft.Text("Contato:", size=14), ft.Text("hugobs4987@gmail.com", size=14, weight=ft.FontWeight.BOLD, color=primary_color)], spacing=5),
                ], spacing=8
            ), padding=15
        ), elevation=2,
    )
    
    return ft.Container(
        content=ft.Column(controls=[
                app_title_section, 
                info_card, 
                ft.Container(
                    content=ft.Text("Obrigado por usar o BoviCheck!", italic=True, text_align=ft.TextAlign.CENTER), 
                    padding=ft.padding.only(top=25, bottom=20)
                )
            ],
            scroll=ft.ScrollMode.ADAPTIVE, 
            horizontal_alignment=ft.CrossAxisAlignment.STRETCH,
        ), 
        alignment=ft.alignment.top_center, 
        expand=True
    )