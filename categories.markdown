---
layout: page
title: Categories
permalink: /categories/
---

{%- assign sorted_categories = site.categories | sort -%}
{%- for category in sorted_categories -%}
## <span id="{{ category[0] | slugify }}">{{ category[0] }}</span>

<ul class="taxonomy-list">
{%- for post in category[1] -%}
  <li><a href="{{ post.url | relative_url }}">{{ post.title }}</a> <span class="archive-date">{{ post.date | date: "%e %B %Y" | strip }}</span></li>
{%- endfor -%}
</ul>
{%- endfor -%}