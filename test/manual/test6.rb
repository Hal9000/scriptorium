require_relative "../../lib/scriptorium"

@repo = Scriptorium::Repo.open("./scriptorium-TEST")

@repo.view("testview")

view = @repo.view

view.paginate_posts

