require "../src/markup"

include Diclionary::Text

Lipsum = markup(
	paragraph(<<-LOREM),
		Lorem ipsum dolor sit amet, consectetur adipiscing elit. \
		Etiam nec tortor id magna vulputate pretium. \
		Suspendisse porta bibendum malesuada. \
		Integer velit diam, egestas non nisi ut, accumsan ornare eros. \
		Aliquam rhoncus elementum cursus. Quisque vitae blandit ligula. \
		Proin elit turpis, ornare et malesuada at, mattis in sem. \
		Aliquam tortor lectus, convallis sit amet tristique ac, rhoncus eu lectus. \
		Pellentesque tempus eleifend eros in elementum. \
		Mauris et pellentesque nisi. Aenean nec felis elit. \
		Sed sit amet tellus et velit luctus laoreet quis sed urna. \
		Sed dictum fringilla nibh sit amet tempor. \
		Nam vel sem tincidunt, tempor turpis ac, cursus mauris.
		LOREM
	paragraph(<<-PLAIN, bold(<<-BOLD), italic(<<-ITALIC), <<-PLAIN, small(<<-SMALL), <<-PLAIN),
		Ut sit amet elementum erat. \
		Morbi auctor ante sit amet justo molestie interdum.
		PLAIN
		 Fusce sed condimentum neque, nec aliquam magna.
		BOLD
		 Maecenas et mollis risus, in facilisis nisl.
		ITALIC
		 Nullam accumsan molestie massa, ac vehicula orci maximus dapibus. \
		Fusce dolor diam, bibendum et lacinia eget, laoreet sed felis.
		PLAIN
		 Integer rutrum quis purus eu molestie. Nulla sagittis convallis scelerisque.
		SMALL
		 Suspendisse vitae eros id leo pharetra dictum vitae elementum arcu.
		PLAIN
	paragraph("Donec vel felis placerat, fermentum quam non, efficitur purus. ",
		bold("Nulla"), " at orci ", bold("fermentum"),
		" dignissim dolor id, ", italic("commodo erat"),
		". Donec laoreet lectus et quam tincidunt laoreet. ",
		small("Praesent vestibulum metus quis mollis blandit."),
		" Vivamus sit amet ", bold("tellus"), " at ", italic("nibh auctor"),
		" consequat. ", bold("Curabitur eu ", italic("interdum"), " nulla."),
		" Cras posuere in leo et venenatis.",
		<<-TEXT),
		 Mauris eget felis eleifend, egestas enim nec, feugiat neque. \
		Donec aliquet volutpat pulvinar. \
		Duis posuere dictum leo, ac luctus orci laoreet ut. \
		Donec eleifend tempus lorem nec accumsan. \
		Duis vitae aliquet ipsum, a cursus urna. \
		Fusce pretium venenatis pulvinar. \
		Aenean convallis lorem ut ligula commodo ultrices.
		TEXT
	paragraph("Donec sit amet facilisis lectus. Integer et fringilla velit. ",
		"Sed aliquam eros ac turpis tristique mollis. ",
		"Maecenas luctus magna ac elit euismod fermentum.",
		ordered_list(
			item(<<-ITEM),
				Curabitur pulvinar purus imperdiet purus fringilla, \
				venenatis facilisis quam efficitur. \
				Nunc justo diam, interdum ut varius a, laoreet ut justo.
				ITEM
			item(<<-ITEM),
				Sed rutrum pulvinar sapien eget feugiat.
				ITEM
			item(<<-ITEM)
				Nulla vulputate mollis nisl eu venenatis. \
				Vestibulum consectetur lorem augue, \
				sed dictum arcu vulputate quis. Phasellus a velit velit. \
				Morbi auctor ante sit amet justo molestie interdum. \
				Fusce sed condimentum neque, nec aliquam magna. \
				Maecenas et mollis risus, in facilisis nisl.
				ITEM
		),
		<<-TEXT
			Proin elementum risus ut leo porttitor tristique. \
			Sed sit amet tellus et velit luctus laoreet quis sed urna. \
			Sed dictum fringilla nibh sit amet tempor.
			TEXT
	),
	paragraph("Donec sit amet facilisis lectus. Integer et fringilla velit. ",
		"Sed aliquam eros ac turpis tristique mollis. ",
		"Maecenas luctus magna ac elit euismod fermentum.",
		ordered_list(
			item(<<-ITEM, ordered_list(item(<<-SUBITEM), item(<<-SUBITEM))),
				Curabitur pulvinar purus imperdiet purus fringilla, \
				venenatis facilisis quam efficitur. \
				Nunc justo diam, interdum ut varius a, laoreet ut justo.
				ITEM
				Integer velit diam, egestas non nisi ut, accumsan ornare eros. \
				Aliquam rhoncus elementum cursus. Quisque vitae blandit ligula.
				SUBITEM
				Mauris et pellentesque nisi. Aenean nec felis elit. \
				Sed sit amet tellus et velit luctus laoreet quis sed urna. \
				Sed dictum fringilla nibh sit amet tempor. \
				Nam vel sem tincidunt, tempor turpis ac, cursus mauris.
				SUBITEM
			item(<<-ITEM),
				Sed rutrum pulvinar sapien eget feugiat.
				ITEM
			item(<<-ITEM)
				Nulla vulputate mollis nisl eu venenatis. \
				Vestibulum consectetur lorem augue, \
				sed dictum arcu vulputate quis. Phasellus a velit velit. \
				Morbi auctor ante sit amet justo molestie interdum. \
				Fusce sed condimentum neque, nec aliquam magna. \
				Maecenas et mollis risus, in facilisis nisl.
				ITEM
		),
		<<-TEXT
			Proin elementum risus ut leo porttitor tristique. \
			Sed sit amet tellus et velit luctus laoreet quis sed urna. \
			Sed dictum fringilla nibh sit amet tempor.
			TEXT
	),
	paragraph("Donec sit amet facilisis lectus. Integer et fringilla velit. ",
		"Sed aliquam eros ac turpis tristique mollis. ",
		"Maecenas luctus magna ac elit euismod fermentum.",
		unordered_list(
			item(<<-ITEM),
				Curabitur pulvinar purus imperdiet purus fringilla, \
				venenatis facilisis quam efficitur. \
				Nunc justo diam, interdum ut varius a, laoreet ut justo.
				ITEM
			item(<<-ITEM),
				Sed rutrum pulvinar sapien eget feugiat.
				ITEM
			item(<<-ITEM)
				Nulla vulputate mollis nisl eu venenatis. \
				Vestibulum consectetur lorem augue, \
				sed dictum arcu vulputate quis. Phasellus a velit velit. \
				Morbi auctor ante sit amet justo molestie interdum. \
				Fusce sed condimentum neque, nec aliquam magna. \
				Maecenas et mollis risus, in facilisis nisl.
				ITEM
		),
		<<-TEXT
			Proin elementum risus ut leo porttitor tristique. \
			Sed sit amet tellus et velit luctus laoreet quis sed urna. \
			Sed dictum fringilla nibh sit amet tempor.
			TEXT
	)
)
