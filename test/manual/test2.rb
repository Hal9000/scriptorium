require_relative "./environment"

manual_setup

create_3_views
@repo.generate_front_page("blog1")

examine("blog1")
