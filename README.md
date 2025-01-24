# field-reveal
Linux command line tool that reveals the fields in Linux files or directories, along with a structured display.

| before | after |
|--------|-------|
|![image](https://github.com/user-attachments/assets/3769ad7c-4be5-441e-b99a-cc3b3971e30f)|![{67F0E505-F90C-49E6-B810-4FC14F8A00BB}](https://github.com/user-attachments/assets/a7f7747a-7cd2-4371-8f86-6bfde92f49e7)|

# why ?
Data fields in Linux are often non-present and requires internet search. \
This is a simple solution to clearly display this basic information.

# contributing
Adding entries to `fields.txt` will grow the use of the tool. \
Each entry contains comma seperated values.

1. Path to file.
2. awk field separator. Defaults to `,` if empty.
3. Optional, use `PFAT` to use regular expression for complex paterns in awk. Defaults to field separator (-FS), if empty.
4. Number of fields.
5. Comma seperated list of the fields present. 

Example:
1. /var/log/apache2/error.log,
2. ([^[:space:]]+|"[^"]+"|\\[[^]]+\\]),
3. FPAT,
4. 5,
5. Timestamp, Error code, Process/Thread IDs, Message code, Message

*All together* the entry should look like this:
```
/var/log/apache2/error.log,([^[:space:]]+|"[^"]+"|\\[[^]]+\\]),FPAT,5, Timestamp, Error code, Process/Thread IDs, Message code, Message
```
