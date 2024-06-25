extends ScrollContainer
var maxScrollLength = 0 
@onready var scrollbar = get_v_scroll_bar()

# TODO: manage max items with variable
func _ready(): 
	scrollbar.changed.connect(handleScrollbarChanged)
	maxScrollLength = scrollbar.max_value

func handleScrollbarChanged(): 
	if maxScrollLength != scrollbar.max_value: 
		maxScrollLength = scrollbar.max_value 
		self.scroll_vertical = maxScrollLength
