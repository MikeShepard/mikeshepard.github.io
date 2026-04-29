---
layout: page
title: Tags
permalink: /tags/
---

{%- assign sorted_tags = site.tags | sort -%}
{%- for tag in sorted_tags -%}
## <span id="{{ tag[0] | slugify }}">{{ tag[0] }}</span>

<ul class="taxonomy-list">
{%- for post in tag[1] -%}
  <li><a href="{{ post.url | relative_url }}">{{ post.title }}</a> <span class="archive-date">{{ post.date | date: "%e %B %Y" | strip }}</span></li>
{%- endfor -%}
</ul>
{%- endfor -%}