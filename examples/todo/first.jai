build :: () {
    args := get_build_options().compile_time_command_line;
    release := array_find(args, "release");

    set_build_options_dc({ do_output = false });

    w := compiler_create_workspace("WebJai");

    options := get_build_options(w);
    copy_commonly_propagated_fields(get_build_options(), *options);

    options.output_type = .EXECUTABLE;
    options.backend     = .LLVM;
    options.os_target   = .WASM;
    options.cpu_target  = .CUSTOM;

    if release {
        set_optimization(*options, .OPTIMIZED_VERY_SMALL, preserve_debug_info = false);
    } else {
        set_optimization(*options, .DEBUG, preserve_debug_info = true);
    }

    options.backtrace_on_crash                  = .OFF;
    options.output_path                         = "public";
    options.output_executable_name              = "main";
    options.llvm_options.target_system_features = "+bulk-memory";
    options.llvm_options.enable_split_modules   = false;
    options.llvm_options.function_sections      = true;
    options.use_custom_link_command             = true;

    import_path: [..] string;
    array_add(*import_path, "../../modules");
    array_add(*import_path, ..options.import_path);
    options.import_path = import_path;

    // STACK_SIZE :: #run megabytes(32);
    // options.additional_linker_arguments = .["--stack-first", "-z", tprint("stack-size=%", STACK_SIZE), "walloc.o"];

    set_build_options(options, w);

    make_directory_if_it_does_not_exist(options.output_path);

    remap_import(w, "*", "Default_Allocator", "Walloc");

    compiler_begin_intercept(w);

    add_build_file("main.jai", w);

    css_emitted := false;

    while true {
        message := compiler_wait_for_message();

        if message.kind == {
            case .TYPECHECKED;
                tc := cast(*Message_Typechecked) message;
                for tc.declarations {
                    decl := it.expression;
                    if decl.name == "WEBJAI_EMITTED_CSS" {
                        if decl.expression && decl.expression.kind == .LITERAL {
                            lit := cast(*Code_Literal) decl.expression;
                            if lit.value_type == .STRING {
                                write_entire_file(tprint("%/style.css", options.output_path), lit._string);
                            }
                        }
                    }
                }

            case .PHASE;
                phase := cast(*Message_Phase) message;
                if phase.phase == .TYPECHECKED_ALL_WE_CAN && !css_emitted {
                    css_emitted = true;
                    add_build_string("#run css_export_declaration();", message.workspace);
                } else if phase.phase == .READY_FOR_CUSTOM_LINK_COMMAND {
                    phase.executable_name = run_link_command(w, phase);
                    compiler_custom_link_command_is_complete(w);
                }

            case .ERROR;
                exit(1);

            case .COMPLETE;
                break;
        }
    }

    compiler_end_intercept(w);

    copy_file("../../public/runtime.js", tprint("%/runtime.js", options.output_path));
}

run_link_command :: (w: Workspace, m: *Message_Phase) -> string {
    options := get_build_options(w);
    output_filename := tprint("%/%.wasm", ifx options.output_path else ".", options.output_executable_name);

    args: [..] string;

    STACK_SIZE :: #run megabytes(32);

    // @Todo: Do we need to build the link command from scratch or can we just modify the default link command arguments?
    #if OS == .WINDOWS {
        array_add(*args, "lld.exe");
    } else #if OS == .MACOS {
        array_add(*args, "lld-macos");
    }  else #if OS == .LINUX {
        array_add(*args, "lld-linux");
    } else {
        assert(false);
    }

    array_add(*args, "-flavor", "wasm");
    array_add(*args, "-mwasm64");
    array_add(*args, "--no-entry");
    array_add(*args, "--import-undefined");

    array_add(*args, "--gc-sections");
    array_add(*args, "--strip-all");

    array_add(*args, "--export=main");
    array_add(*args, "--export=wasm_get_js_command_buffer_ptr");
    array_add(*args, "--export=wasm_handle_js_commands");
    array_add(*args, "--export=wasm_push_string");

    array_add(*args, "--stack-first");
    array_add(*args, "-z", tprint("stack-size=%", STACK_SIZE));
    array_add(*args, "../../walloc.o");

    for m.compiler_generated_object_files array_add(*args, it);

    array_add(*args, "-o", output_filename);

    log("Running linker: %\n", get_quoted_command_string(args));

    result := run_command(..args);
    if result.exit_code != 0 {
        details: string;
        if result.type == {
            case .FAILED_TO_LAUNCH;
                details = "Could not launch linker.";
            case .SIGNALED;
                details = tprint("Linker caught signal %.", result.signal);
            case;
                details = tprint("Linker exit code %.", result.exit_code);
        }

        log_error("Error: Link step failed! %", details);
        compiler_set_workspace_status(.FAILED, w);
    }

    return output_filename;
}

kilobytes :: (n: int) -> int {
    return n * 1024;
}

megabytes :: (n: int) -> int {
    return kilobytes(n * 1024);
}

#run build();

#import "Basic";
#import "Compiler";
#import "File";
#import "File_Utilities";
#import "String";
#import "Process";
