package com.memetoclasm.districtlive.ingestion

interface NotificationPort {
    fun notifySourceUnhealthy(sourceName: String, consecutiveFailures: Int, errorMessage: String?)
    fun notifySourceRecovered(sourceName: String)
}
