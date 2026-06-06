class DummyVectorDB:
    def __init__(self):
        self._store = {}

    def add(self, key: str, value: str):
        self._store[key] = value

    def get(self, key: str):
        return self._store.get(key)

_vector_db: DummyVectorDB | None = None

def get_vector_db() -> DummyVectorDB:
    global _vector_db
    if _vector_db is None:
        _vector_db = DummyVectorDB()
    return _vector_db
