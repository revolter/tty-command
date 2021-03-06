# encoding: utf-8

RSpec.describe TTY::Command, '#run' do
  it 'runs command and prints to stdout' do
    output = StringIO.new
    command = TTY::Command.new(output: output)

    out, err = command.run(:echo, 'hello')

    expect(out).to eq("hello\n")
    expect(err).to eq("")
  end

  it 'runs command successfully with logging' do
    output = StringIO.new
    uuid= 'xxxx'
    allow(SecureRandom).to receive(:uuid).and_return(uuid)
    command = TTY::Command.new(output: output)

    command.run(:echo, 'hello')

    output.rewind
    lines = output.readlines
    lines.last.gsub!(/\d+\.\d+/, 'x')
    expect(lines).to eq([
      "[\e[32m#{uuid}\e[0m] Running \e[33;1mecho hello\e[0m\n",
      "[\e[32m#{uuid}\e[0m] \thello\n",
      "[\e[32m#{uuid}\e[0m] Finished in x seconds with exit status 0 (\e[32;1msuccessful\e[0m)\n"
    ])
  end

  it 'runs command successfully with logging without color' do
    output = StringIO.new
    uuid= 'xxxx'
    allow(SecureRandom).to receive(:uuid).and_return(uuid)
    command = TTY::Command.new(output: output, color: false)

    command.run(:echo, 'hello')

    output.rewind
    lines = output.readlines
    lines.last.gsub!(/\d+\.\d+/, 'x')
    expect(lines).to eq([
      "[#{uuid}] Running echo hello\n",
      "[#{uuid}] \thello\n",
      "[#{uuid}] Finished in x seconds with exit status 0 (successful)\n"
    ])
  end

  it 'runs command successfully with logging without uuid' do
    output = StringIO.new
    command = TTY::Command.new(output: output, uuid: false)

    command.run(:echo, 'hello')
    output.rewind

    lines = output.readlines
    lines.last.gsub!(/\d+\.\d+/, 'x')
    expect(lines).to eq([
      "Running \e[33;1mecho hello\e[0m\n",
      "\thello\n",
      "Finished in x seconds with exit status 0 (\e[32;1msuccessful\e[0m)\n"
    ])
  end

  it "runs command and fails with logging" do
    non_zero_exit = tmp_path('non_zero_exit')
    output = StringIO.new
    uuid= 'xxxx'
    allow(SecureRandom).to receive(:uuid).and_return(uuid)
    command = TTY::Command.new(output: output)

    command.run!("ruby #{non_zero_exit}")

    output.rewind
    lines = output.readlines
    lines.last.gsub!(/\d+\.\d+/, 'x')
    expect(lines).to eq([
      "[\e[32m#{uuid}\e[0m] Running \e[33;1mruby #{non_zero_exit}\e[0m\n",
      "[\e[32m#{uuid}\e[0m] \tnooo\n",
      "[\e[32m#{uuid}\e[0m] Finished in x seconds with exit status 1 (\e[31;1mfailed\e[0m)\n"
    ])
  end

  it "raises ExitError on command failure" do
    non_zero_exit = tmp_path('non_zero_exit')
    output = StringIO.new
    command = TTY::Command.new(output: output)

    expect {
      command.run("ruby #{non_zero_exit}")
    }.to raise_error(TTY::Command::ExitError,
      ["Running `ruby #{non_zero_exit}` failed with",
       "  exit status: 1",
       "  stdout: nooo",
       "  stderr: Nothing written\n"].join("\n")
    )
  end

  it "reads user input data" do
    cli = tmp_path('cli')
    output = StringIO.new
    command = TTY::Command.new(output: output)

    out, _ = command.run("ruby #{cli}", input: "Piotr\n")

    expect(out).to eq("Your name: Piotr\n")
  end

  it "streams output data" do
    stream = tmp_path('stream')
    output = StringIO.new
    command = TTY::Command.new(output: output)
    output = ''
    error = ''
    command.run("ruby #{stream}") do |out, err|
     output << out if out
     error << err if err
    end
    expect(output).to eq("hello 1\nhello 2\nhello 3\n")
    expect(error).to eq('')
  end

  it "preserves ANSI codes" do
    output = StringIO.new
    command = TTY::Command.new(output: output, printer: :quiet)

    out, _ = command.run("echo \e[35mhello\e[0m")

    expect(out).to eq("\e[35mhello\e[0m\n")
    expect(output.string).to eq("\e[35mhello\e[0m\n")
  end
end
