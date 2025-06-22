import flet as ft
from controllers.main_controller import MainController
from models.definitions import VERSION_NUMBER
import os
from dotenv import load_dotenv
import tabulate

def main(page: ft.Page):
    load_dotenv()
    
    page.title = f"BoviCheck AI v{VERSION_NUMBER}"
    page.window_icon = "icontest.ico"
    page.vertical_alignment = ft.MainAxisAlignment.START
    page.horizontal_alignment = ft.CrossAxisAlignment.STRETCH
    page.padding = 0
    page.fonts = {
        "OpenSans": "https://fonts.googleapis.com/css2?family=Open+Sans:wght@400;600;700&display=swap"
    }

    app_controller = MainController(page)

    page.on_route_change = app_controller.navigation.route_change_handler
    page.on_view_pop = app_controller.navigation.view_pop_handler

    page.go("/dashboard")


if __name__ == "__main__":
    ft.app(
        target=main,
        assets_dir="assets"
    )