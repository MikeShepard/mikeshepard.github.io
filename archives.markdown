---
layout: page
title: Archives
permalink: /archives/
---

{%- assign posts_by_month = site.posts | group_by_exp: 'post', 'post.date | date: "%B %Y"' -%}
{%- for month in posts_by_month -%}
## <span id="{{ month.items.first.date | date: '%Y-%m' }}">{{ month.name }}</span>

<ul class="archive-list">
{%- for post in month.items -%}
  <li><a href="{{ post.url | relative_url }}">{{ post.title }}</a> <span class="archive-date">{{ post.date | date: "%e %B %Y" | strip }}</span></li>
{%- endfor -%}
</ul>
{%- endfor -%}