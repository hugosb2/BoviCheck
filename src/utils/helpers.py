from urllib.parse import quote, unquote

def to_safe_route_param(name: str) -> str:
    processed_name = name.replace(" ", "_").replace("/", "__SLASH__")
    return quote(processed_name)

def from_safe_route_param(param: str) -> str:
    decoded_param = unquote(param)
    return decoded_param.replace("__SLASH__", "/").replace("_", " ")