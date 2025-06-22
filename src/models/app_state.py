import flet as ft
from datetime import datetime
import os
import uuid

class AppState:
    def __init__(self):
        self.calculated_indices = {}
        self.theme_preference = {
            "theme_mode": ft.ThemeMode.SYSTEM,
            "primary_color_name": "TEAL_ACCENT_700",
        }
        self.ai_settings = {
            "enabled": False,
            "api_key": os.getenv("GEMINI_API_KEY"),
            "suggestions_on_dashboard": False,
        }
        self.chat_history = []
        self.current_chat_id = None

    def to_dict(self) -> dict:
        theme_prefs = self.theme_preference.copy()
        if isinstance(theme_prefs.get("theme_mode"), ft.ThemeMode):
            theme_prefs["theme_mode"] = theme_prefs["theme_mode"].value

        return {
            "calculated_indices": self.calculated_indices,
            "theme_preference": theme_prefs,
            "ai_settings": self.ai_settings,
            "chat_history": self.chat_history
        }

    def from_dict(self, data: dict):
        self.calculated_indices = data.get("calculated_indices", {})
        for index_name, results in self.calculated_indices.items():
            for result in results:
                result.setdefault("id", str(uuid.uuid4()))

        theme_prefs = data.get("theme_preference", {})
        self.theme_preference["primary_color_name"] = theme_prefs.get("primary_color_name", "TEAL_ACCENT_700")
        theme_mode_str = theme_prefs.get("theme_mode", "system")
        try:
            self.theme_preference["theme_mode"] = ft.ThemeMode(theme_mode_str)
        except (ValueError, AttributeError):
            self.theme_preference["theme_mode"] = ft.ThemeMode.SYSTEM

        default_ai_settings = {
            "enabled": False,
            "api_key": os.getenv("GEMINI_API_KEY"),
            "suggestions_on_dashboard": False,
        }
        loaded_ai_settings = data.get("ai_settings", default_ai_settings)
        loaded_ai_settings.setdefault("api_key", os.getenv("GEMINI_API_KEY"))
        self.ai_settings = loaded_ai_settings


        self.chat_history = data.get("chat_history", [])

    def reset(self):
        self.calculated_indices.clear()
        self.chat_history.clear()

    def get_calculation_by_id(self, index_name: str, calc_id: str):
        if index_name in self.calculated_indices:
            for i, calc in enumerate(self.calculated_indices.get(index_name, [])):
                if calc.get("id") == calc_id:
                    return calc, i
        return None, None

    def update_calculation_by_id(self, index_name: str, calc_id: str, new_data: dict):
        calc, index_in_list = self.get_calculation_by_id(index_name, calc_id)
        if calc is not None and index_in_list is not None:
            updated_entry = {**calc, **new_data, "id": calc_id}
            self.calculated_indices[index_name][index_in_list] = updated_entry
            return True
        return False

    def add_new_calculation(self, index_name: str, calculation_entry: dict):
        if index_name not in self.calculated_indices:
            self.calculated_indices[index_name] = []
        
        self.calculated_indices[index_name].append(calculation_entry)
        return calculation_entry["id"]

    def get_chat_by_id(self, chat_id: str) -> dict | None:
        for chat in self.chat_history:
            if chat.get("id") == chat_id:
                return chat
        return None
        
    def get_current_chat(self) -> dict | None:
        return self.get_chat_by_id(self.current_chat_id)

    def delete_chat_by_id(self, chat_id: str) -> bool:
        chat_to_delete = self.get_chat_by_id(chat_id)
        if chat_to_delete:
            self.chat_history.remove(chat_to_delete)
            return True
        return False
        
    def update_chat_title(self, chat_id: str, new_title: str) -> bool:
        chat = self.get_chat_by_id(chat_id)
        if chat:
            chat['title'] = new_title
            return True
        return False