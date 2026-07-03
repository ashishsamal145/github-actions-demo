Describe "Endpoint Regression Tests" {
    BeforeAll {
        $ProgressPreference = 'SilentlyContinue'
    }

    Context "HTTP Status Code Verification" {
        It "Frontend returns 200 OK" {
            $response = Invoke-WebRequest -Uri "https://purva.zenalyst.ai/" -Method Get -MaximumRedirection 0 -SkipHttpErrorCheck
            $response.StatusCode | Should -Be 200
        }

        It "Backend returns 200 OK" {
            $response = Invoke-WebRequest -Uri "https://purva.zenalyst.ai/api/backend/api/health" -Method Get -SkipHttpErrorCheck
            $response.StatusCode | Should -Be 200
        }

        It "AI Engine returns 200 OK" {
            $response = Invoke-WebRequest -Uri "https://purva.zenalyst.ai/api/ai-engine/health" -Method Get -SkipHttpErrorCheck
            $response.StatusCode | Should -Be 200
        }

        It "HTTP redirects to HTTPS (301)" {
            # FIXED: Reverted back to your exact requested URL
            $response = Invoke-WebRequest -Uri "http://zenalyst.ai" -Method Get -MaximumRedirection 0 -SkipHttpErrorCheck -ErrorAction SilentlyContinue
            $response.StatusCode | Should -Be 301
        }
    }

    Context "SSL Certificate Verification via OpenSSL" {
        # FIXED: Wrapped in bash -c so the Linux pipeline pipes correctly without returning $null to Pester
        $sslOutput = bash -c 'echo | openssl s_client -servername purva.zenalyst.ai -connect 20.219.60.145:443 2>/dev/null | openssl x509 -noout -subject -dates'

        It "Successfully retrieved OpenSSL data" {
            $sslOutput | Should -Not -BeNullOrEmpty
        }

        It "Has the correct Common Name (Subject)" {
            $sslOutput | Should -Match "subject=CN=purva.zenalyst.ai"
        }

        It "Certificate is currently active (notBefore check)" {
            $notBeforeLine = $sslOutput | Where-Object { $_ -match "^notBefore=" }
            $notBeforeStr = ($notBeforeLine -replace "notBefore=", "").Trim()
            
            $formats = @("MMM dd HH:mm:ss yyyy 'GMT'", "MMM  d HH:mm:ss yyyy 'GMT'")
            $notBeforeDate = [DateTime]::ParseExact($notBeforeStr, $formats, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AssumeUniversal)
            
            $notBeforeDate | Should -BeLessThan (Get-Date)
        }

        It "Certificate is not expired (notAfter check)" {
            $notAfterLine = $sslOutput | Where-Object { $_ -match "^notAfter=" }
            $notAfterStr = ($notAfterLine -replace "notAfter=", "").Trim()
            
            $formats = @("MMM dd HH:mm:ss yyyy 'GMT'", "MMM  d HH:mm:ss yyyy 'GMT'")
            $notAfterDate = [DateTime]::ParseExact($notAfterStr, $formats, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AssumeUniversal)
            
            $notAfterDate | Should -BeGreaterThan (Get-Date)
        }

        It "Certificate does not expire within the next 14 days" {
            $notAfterLine = $sslOutput | Where-Object { $_ -match "^notAfter=" }
            $notAfterStr = ($notAfterLine -replace "notAfter=", "").Trim()
            
            $formats = @("MMM dd HH:mm:ss yyyy 'GMT'", "MMM  d HH:mm:ss yyyy 'GMT'")
            $notAfterDate = [DateTime]::ParseExact($notAfterStr, $formats, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AssumeUniversal)
            
            $minimumSafeDate = (Get-Date).AddDays(14)
            $notAfterDate | Should -BeGreaterThan $minimumSafeDate
        }
    }
}
