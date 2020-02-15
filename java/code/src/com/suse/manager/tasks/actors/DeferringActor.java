package com.suse.manager.tasks.actors;

import static akka.actor.typed.javadsl.Behaviors.receive;
import static akka.actor.typed.javadsl.Behaviors.setup;

import com.suse.manager.tasks.Actor;
import com.suse.manager.tasks.Command;
import org.apache.log4j.Logger;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Optional;

import akka.actor.typed.ActorRef;
import akka.actor.typed.Behavior;
import akka.actor.typed.javadsl.ActorContext;

/** Defers sending a @{@link Command} after a transaction is finished. */
public class DeferringActor implements Actor {

    private final static Logger LOG = Logger.getLogger(DeferringActor.class);


    public static class DeferCommandMessage implements Command {
        private final Integer accumulatorKey;
        private final Command command;

        public DeferCommandMessage(Integer accumulatorKey, Command command) {
            this.accumulatorKey = accumulatorKey;
            this.command = command;
        }
    }

    public static class ClearDeferredMessage implements Command {
        private final Integer accumulatorKey;

        public ClearDeferredMessage(Integer accumulatorKey) {
            this.accumulatorKey = accumulatorKey;
        }
    }

    public static class TellDeferredMessage implements Command {
        private final Integer accumulatorKey;

        public TellDeferredMessage(Integer accumulatorKey) {
            this.accumulatorKey = accumulatorKey;
        }
    }

    public Behavior<Command> create(ActorRef<Command> guardian) {
        return setup(context -> build(context, new HashMap<Integer, HashSet<Command>>(), guardian));
    }

    private Behavior<Command> build(ActorContext<Command> context, Map<Integer, HashSet<Command>> accumulator, ActorRef<Command> guardian) {
        return receive(Command.class)
                .onMessage(DeferCommandMessage.class, message -> onRegisterMessage(context, message, accumulator, guardian))
                .onMessage(ClearDeferredMessage.class, message -> onClearMessage(context, message, accumulator, guardian))
                .onMessage(TellDeferredMessage.class, message -> onTellMessage(context, message, accumulator, guardian))
                .build();
    }

    private Behavior<Command> onRegisterMessage(ActorContext<Command> context, DeferCommandMessage message,
                                                Map<Integer, HashSet<Command>> accumulator, ActorRef<Command> guardian) {
        var set = accumulator.getOrDefault(message.accumulatorKey, new HashSet<Command>());
        set.add(message.command);
        accumulator.put(message.accumulatorKey, set);

        return build(context, accumulator, guardian);
    }

    private Behavior<Command> onClearMessage(ActorContext<Command> context, ClearDeferredMessage message,
                                             Map<Integer, HashSet<Command>> accumulator, ActorRef<Command> guardian) {
        accumulator.remove(message.accumulatorKey);
     return build(context, accumulator, guardian);
    }

    private Behavior<Command> onTellMessage(ActorContext<Command> context, TellDeferredMessage message,
                                            Map<Integer, HashSet<Command>> accumulator, ActorRef<Command> guardian) {
        Optional.ofNullable(accumulator.remove(message.accumulatorKey))
                .ifPresent(commands -> commands.forEach(c -> guardian.tell(c)));
        return build(context, accumulator, guardian);
    }
}
