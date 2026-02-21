package com.example.lifexp

import java.time.LocalDate
import java.time.format.DateTimeFormatter

object DateUtil {
    fun todayLocalIsoDate(): String {
        return LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE)
    }
}
