package com.memetoclasm.districtlive.event

object SlugUtils {
    fun slugify(text: String): String =
        text.lowercase()
            .replace(Regex("[^a-z0-9]+"), "-")
            .trim('-')
}
