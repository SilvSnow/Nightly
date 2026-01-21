from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

# Load model once at module level (lazy initialization)
_model = None
_embedding_cache = {}

def _get_model():
    global _model
    if _model is None:
        _model = SentenceTransformer('all-MiniLM-L6-v2')
    return _model

def _get_embedding(activity: str) -> np.ndarray:
    """Get embedding for an activity, using cache to avoid recomputation."""
    activity = activity.lower().strip()
    if activity not in _embedding_cache:
        model = _get_model()
        _embedding_cache[activity] = model.encode(activity)
    return _embedding_cache[activity]

def activityMatchScore(group_a, group_b) -> float:
    """
    Compute activity compatibility using sentence-transformer embeddings.
    Returns cosine similarity between activity embeddings (0.0 to 1.0).

    Activities: dinner, bar/bar-hopping, nightclub, concert, house party, etc.
    """
    activity_a = group_a.get("ideal_activity")
    activity_b = group_b.get("ideal_activity")

    # Handle missing activities
    if not activity_a or not activity_b:
        return 0.5  # Neutral score if activity not specified

    # Get embeddings
    emb_a = _get_embedding(activity_a)
    emb_b = _get_embedding(activity_b)

    # Compute cosine similarity
    similarity = cosine_similarity(
        emb_a.reshape(1, -1),
        emb_b.reshape(1, -1)
    )[0][0]

    # Normalize from [-1, 1] to [0, 1]
    normalized = (similarity + 1) / 2

    return max(0.0, min(1.0, float(normalized)))
