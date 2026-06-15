Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$outDir = Join-Path $root "project_docs\diagrams"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function Color($hex) {
    return [System.Drawing.ColorTranslator]::FromHtml($hex)
}

function New-Canvas {
    param([string]$Title)
    $bmp = New-Object System.Drawing.Bitmap 1600, 900
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $g.Clear([System.Drawing.Color]::White)

    $titleFont = New-Object System.Drawing.Font "Segoe UI", 30, ([System.Drawing.FontStyle]::Bold)
    $titleBrush = New-Object System.Drawing.SolidBrush (Color "#173f8a")
    $g.DrawString($Title, $titleFont, $titleBrush, 60, 35)
    $pen = New-Object System.Drawing.Pen (Color "#d7dde8"), 2
    $g.DrawLine($pen, 60, 92, 1540, 92)
    $pen.Dispose()
    $titleBrush.Dispose()
    $titleFont.Dispose()
    return @($bmp, $g)
}

function Draw-Box {
    param(
        [System.Drawing.Graphics]$G,
        [int]$X,
        [int]$Y,
        [int]$W,
        [int]$H,
        [string]$Text,
        [string]$Fill = "#f5f7fb",
        [string]$Border = "#173f8a",
        [int]$FontSize = 17
    )

    $rect = New-Object System.Drawing.Rectangle $X, $Y, $W, $H
    $textRect = New-Object System.Drawing.RectangleF ([float]$X), ([float]$Y), ([float]$W), ([float]$H)
    $brush = New-Object System.Drawing.SolidBrush (Color $Fill)
    $pen = New-Object System.Drawing.Pen (Color $Border), 3
    $G.FillRectangle($brush, $rect)
    $G.DrawRectangle($pen, $rect)

    $font = New-Object System.Drawing.Font "Segoe UI", $FontSize, ([System.Drawing.FontStyle]::Bold)
    $textBrush = New-Object System.Drawing.SolidBrush (Color "#1f2937")
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $G.DrawString($Text, $font, $textBrush, $textRect, $format)

    $format.Dispose()
    $textBrush.Dispose()
    $font.Dispose()
    $pen.Dispose()
    $brush.Dispose()
}

function Draw-Arrow {
    param(
        [System.Drawing.Graphics]$G,
        [int]$X1,
        [int]$Y1,
        [int]$X2,
        [int]$Y2,
        [string]$Color = "#173f8a"
    )

    $pen = New-Object System.Drawing.Pen (Color $Color), 4
    $cap = New-Object System.Drawing.Drawing2D.AdjustableArrowCap 7, 7
    $pen.CustomEndCap = $cap
    $G.DrawLine($pen, $X1, $Y1, $X2, $Y2)
    $cap.Dispose()
    $pen.Dispose()
}

function Save-Diagram {
    param([System.Drawing.Bitmap]$Bitmap, [System.Drawing.Graphics]$Graphics, [string]$FileName)
    $path = Join-Path $outDir $FileName
    $Bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $Graphics.Dispose()
    $Bitmap.Dispose()
    Write-Host $path
}

function New-ExistingArchitecture {
    $items = New-Canvas "Architecture of the Existing System"
    $bmp = $items[0]
    $g = $items[1]

    Draw-Box $g 60 385 230 120 "Student /`nCandidate" "#eaf2ff" "#173f8a" 18
    $sources = @(
        @(430, 150, "University`nwebsite"),
        @(780, 150, "Student`nportal"),
        @(1130, 150, "Physical`noffices"),
        @(430, 390, "Lecturers /`ncourse reps"),
        @(780, 390, "Course`nmaterials"),
        @(1130, 390, "Peers and`nnotice boards")
    )

    foreach ($s in $sources) {
        Draw-Box $g $s[0] $s[1] 260 120 $s[2] "#fff9db" "#b89400" 17
        Draw-Arrow $g 290 445 ($s[0]) ($s[1] + 60) "#6b7280"
    }

    Draw-Box $g 610 675 380 110 "Manual searching`nand repeated inquiries" "#fef2f2" "#b42318" 17
    Draw-Box $g 1100 675 360 110 "Delayed feedback`nNo personal tracking" "#fef2f2" "#b42318" 17
    Draw-Arrow $g 760 510 760 675 "#b42318"
    Draw-Arrow $g 950 730 1100 730 "#b42318"

    Save-Diagram $bmp $g "existing_system_architecture.png"
}

function New-ProposedArchitecture {
    $items = New-Canvas "Architecture of the Proposed Eve System"
    $bmp = $items[0]
    $g = $items[1]

    Draw-Box $g 60 175 250 85 "Guest" "#eaf2ff" "#173f8a" 18
    Draw-Box $g 60 310 250 85 "Student" "#eaf2ff" "#173f8a" 18
    Draw-Box $g 60 445 250 85 "Lecturer" "#eaf2ff" "#173f8a" 18
    Draw-Box $g 390 280 270 150 "Flutter Web /`nMobile Client" "#ecfdf3" "#027a48" 18
    Draw-Box $g 750 280 280 150 "FastAPI Backend`nEve Core" "#f5f7fb" "#173f8a" 18
    Draw-Box $g 1110 145 330 95 "Guardrails +`nRole-Based Access" "#fff9db" "#b89400" 16
    Draw-Box $g 1110 285 330 95 "RAG + Curated`nESUI Knowledge" "#eaf2ff" "#173f8a" 16
    Draw-Box $g 1110 425 330 95 "Academic Services +`nStudent Records" "#ecfdf3" "#027a48" 16
    Draw-Box $g 1110 565 330 95 "SQLite Progress +`nPeer-Note Review" "#fef2f2" "#b42318" 16
    Draw-Box $g 750 595 280 90 "Optional OpenAI`nResponses API" "#f4f0ff" "#6941c6" 16

    Draw-Arrow $g 310 220 390 330
    Draw-Arrow $g 310 353 390 355
    Draw-Arrow $g 310 490 390 380
    Draw-Arrow $g 660 355 750 355
    Draw-Arrow $g 1030 355 1110 190
    Draw-Arrow $g 1030 355 1110 333
    Draw-Arrow $g 1030 355 1110 470
    Draw-Arrow $g 1030 355 1110 610
    Draw-Arrow $g 890 430 890 595 "#6941c6"

    Save-Diagram $bmp $g "proposed_system_architecture.png"
}

function New-DataFlowDiagram {
    $items = New-Canvas "Data Flow Diagram"
    $bmp = $items[0]
    $g = $items[1]

    Draw-Box $g 70 360 210 100 "User" "#eaf2ff" "#173f8a" 18
    Draw-Box $g 350 360 240 100 "Flutter`nClient" "#ecfdf3" "#027a48" 18
    Draw-Box $g 660 360 240 100 "API`nRequest" "#f5f7fb" "#173f8a" 18
    Draw-Box $g 970 270 260 100 "Guardrail +`nAuthorization" "#fff9db" "#b89400" 16
    Draw-Box $g 970 470 260 100 "Intent +`nAcademic Logic" "#eaf2ff" "#173f8a" 16
    Draw-Box $g 1310 270 230 100 "Knowledge`nRetrieval" "#ecfdf3" "#027a48" 16
    Draw-Box $g 1310 470 230 100 "SQLite +`nRecords" "#fef2f2" "#b42318" 16
    Draw-Box $g 660 650 300 100 "Grounded Eve`nResponse" "#f4f0ff" "#6941c6" 17

    Draw-Arrow $g 280 410 350 410
    Draw-Arrow $g 590 410 660 410
    Draw-Arrow $g 900 410 970 320
    Draw-Arrow $g 900 410 970 520
    Draw-Arrow $g 1230 320 1310 320
    Draw-Arrow $g 1230 520 1310 520
    Draw-Arrow $g 1380 570 960 690 "#6941c6"
    Draw-Arrow $g 790 650 470 460 "#6941c6"
    Draw-Arrow $g 350 390 280 390 "#6941c6"

    Save-Diagram $bmp $g "data_flow_diagram.png"
}

function New-DatabaseErd {
    $items = New-Canvas "Database / Storage Design"
    $bmp = $items[0]
    $g = $items[1]

    Draw-Box $g 120 170 430 240 "learning_sessions`n- session_id PK`n- user_id`n- course_code`n- topic`n- created_at`n- completed_at" "#eaf2ff" "#173f8a" 15
    Draw-Box $g 930 170 430 240 "learning_answers`n- id PK`n- session_id FK`n- question`n- answer`n- score`n- feedback" "#ecfdf3" "#027a48" 15
    Draw-Box $g 120 545 430 230 "peer_notes`n- note_id PK`n- user_id`n- course_code`n- content`n- status" "#fff9db" "#b89400" 15
    Draw-Box $g 930 545 430 230 "peer_note_reviews`n- id PK`n- note_id FK`n- reviewer_id`n- action`n- comment" "#fef2f2" "#b42318" 15

    Draw-Arrow $g 550 290 930 290 "#173f8a"
    Draw-Arrow $g 550 660 930 660 "#b42318"

    $font = New-Object System.Drawing.Font "Segoe UI", 18, ([System.Drawing.FontStyle]::Bold)
    $brush = New-Object System.Drawing.SolidBrush (Color "#1f2937")
    $g.DrawString("one session has many answers", $font, $brush, 585, 245)
    $g.DrawString("one note can receive review actions", $font, $brush, 565, 615)
    $brush.Dispose()
    $font.Dispose()

    Save-Diagram $bmp $g "database_erd.png"
}

New-ExistingArchitecture
New-ProposedArchitecture
New-DataFlowDiagram
New-DatabaseErd
