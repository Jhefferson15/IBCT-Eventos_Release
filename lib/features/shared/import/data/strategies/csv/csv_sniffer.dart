
import 'package:csv/csv.dart';
import 'dart:math';

class CsvConfig {
  final String fieldDelimiter;
  final String textDelimiter;
  final String eol;

  CsvConfig({
    required this.fieldDelimiter,
    this.textDelimiter = '"',
    required this.eol,
  });
}

class CsvSniffer {
  /// Analyzes the content to find the best CSV configuration.
  CsvConfig sniff(String content) {
    if (content.isEmpty) {
      return CsvConfig(fieldDelimiter: ',', eol: '\n');
    }

    // Candidates
    final delimiters = [',', ';', '\t', '|'];
    final eols = ['\n', '\r\n', '\r'];

    // If content is huge, take a sample (e.g., first 10000 chars)
    // IMPORTANT: Make sure we cut at a newline to avoid creating a fake ragged last row
    String sample = content;
    if (content.length > 10000) {
      int cutIndex = content.lastIndexOf('\n', 10000);
      if (cutIndex == -1) cutIndex = 10000; // Fallback if no newline found (weird)
      sample = content.substring(0, cutIndex);
    }
    
    // STRATEGY: Try Standard/Optimistic First
    // If standard comma works perfectly, don't overthink it.
    final standardScore = _score(sample, ',', '\n');
    if (standardScore > 10.0) { // Arbitrary high threshold meaning "Good rows, consistent, no penalty"
       // Check if it's really good (variance 0, sensible cols)
       // We can just rely on the sniffing loop finding it, BUT ensuring ',' is checked first/favored 
       // or returning early can save time.
       // For now, let's just let the loop run but ensure ',' is in the candidates.
    }

    ScoredConfig? bestConfig;
    double bestScore = -1.0;

    for (var eol in eols) {
      for (var delimiter in delimiters) {
        final score = _score(sample, delimiter, eol);
        
        if (score > bestScore) {
          bestScore = score;
          bestConfig = ScoredConfig(delimiter, eol, score);
        }
      }
    }

    if (bestConfig != null) {
      // Fallback: If score is very low (e.g. 0 rows or 1 row with 1 col), default to comma/\n
      // But usually checking non-zero is enough.
      return CsvConfig(
        fieldDelimiter: bestConfig.delimiter, 
        eol: bestConfig.eol
      );
    }

    return CsvConfig(fieldDelimiter: ',', eol: '\n');
  }

  double _score(String content, String delimiter, String eol) {
    // Basic criteria:
    // 1. Must parse into > 1 rows (ideally).
    // 2. Rows should have consistent column counts (Low Standard Deviation).
    // 3. Column count should be reasonable (e.g. > 1 and < 100).
    
    try {
      final rows = CsvToListConverter(
        fieldDelimiter: delimiter,
        eol: eol,
        shouldParseNumbers: false,
        allowInvalid: true,
      ).convert(content);

      if (rows.isEmpty) return 0.0;

      final int rowCount = rows.length;
      if (rowCount < 2) {
        // Single row is suspicious but possible. 
        // If it parses to 1 row with 1000 columns, that's bad.
        if (rows.first.length > 50) return 0.1; // Penalty for explosion
        return 0.5; // Neutral
      }

      // Calculate column consistency
      final colCounts = rows.map((r) => r.length).toList();
      final double avgCols = colCounts.reduce((a, b) => a + b) / rowCount;
      
      // Variance
      double variance = 0.0;
      for (var count in colCounts) {
        variance += pow(count - avgCols, 2);
      }
      variance /= rowCount;
      final double stdDev = sqrt(variance);

      // Score Calculation
      // We want high row count (within reason) and LOW stdDev.
      // We also want a reasonable number of columns (e.g. 2-20).
      
      double score = 10.0; // Base score

      // Penalize inconsistency
      if (stdDev > 0) {
        score -= (stdDev * 5); // Heavy penalty for jagged rows
      }

      // Penalize too few or too many columns
      if (avgCols < 1.5) score -= 5; // Likely failed split
      if (avgCols > 50) score -= 5; // Likely missed newline

      // Reward recognizing multiple rows
      score += min(rowCount, 10) * 0.5;

      return score;
    } catch (e) {
      return 0.0;
    }
  }
}

class ScoredConfig {
  final String delimiter;
  final String eol;
  final double score;

  ScoredConfig(this.delimiter, this.eol, this.score);
}
