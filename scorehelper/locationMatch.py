# Location match scoring: dealbreaker if locations differ
def location_match(group1_location_id, group2_location_id):
	"""
	Returns 1.0 if locations match, 0.0 if they do not (dealbreaker).
	This will be the implementation for now, but we can change it later once
	our locations become more specific (i.e. neighborhoods in Montreal)
	"""
	if group1_location_id == group2_location_id:
		return 1.0
	else:
		return 0.0
