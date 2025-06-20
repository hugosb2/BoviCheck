import json
import os
from .app_state import AppState

DATA_FILENAME = "bovicheck_data.json"

def save_state(state: AppState):
    data_dir = _get_data_dir()
    filepath = os.path.join(data_dir, DATA_FILENAME)
    data_to_save = state.to_dict()
    _save_json(filepath, data_to_save)

def load_state(state: AppState):
    data_dir = _get_data_dir()
    filepath = os.path.join(data_dir, DATA_FILENAME)
    
    loaded_data = _load_json(filepath)
    if loaded_data:
        state.from_dict(loaded_data)

def _get_data_dir() -> str:
    if os.name == 'posix': # Android
        app_files_dir = os.getenv("FLET_APP_FILES_DIR", ".")
        return app_files_dir
    else: # Windows, etc.
        return "."

def _save_json(filepath: str, data: dict):
    try:
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        with open(filepath, "w", encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=4)
    except Exception as e:
        print(f"Erro ao salvar {filepath}: {e}")

def _load_json(filepath: str) -> dict | None:
    if not os.path.exists(filepath):
        return None
    try:
        with open(filepath, "r", encoding='utf-8') as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError, Exception) as e:
        print(f"Erro ao carregar {filepath}: {e}")
        return None